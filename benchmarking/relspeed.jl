using FastRationals
using Polynomials, LinearAlgebra, BenchmarkTools, MacroTools

BenchmarkTools.DEFAULT_PARAMETERS.evals = 1;
BenchmarkTools.DEFAULT_PARAMETERS.samples = 200;
BenchmarkTools.DEFAULT_PARAMETERS.time_tolerance = 2.0e-9;
BenchmarkTools.DEFAULT_PARAMETERS.overhead = BenchmarkTools.estimate_overhead();

walk(x, inner, outer) = outer(x)
walk(x::Expr, inner, outer) = outer(Expr(x.head, map(inner, x.args)...))
postwalk`f, x) = walk(x, x -> postwalk(f, x), f)

function _byref(expr::Expr)
    if expr.head == :$
        :($(Expr(:$, :(Ref($(expr.args...)))))[])
    else
        expr
    end
end
_byref(x)  = x

"""
    @noelide @btime expression
    @noelide @belapsed expression
    @noelide @benchmark expression

Wraps all interpolated code in _expression_ in a __Ref()__ to
stop the compiler from cheating at simple benchmarks. Works
with any macro that accepts interpolation
Example
    julia> @btime \$a + \$b
      0.024 ns (0 allocations: 0 bytes)
    3

    julia> @noelide @btime \$a + \$b
      1.277 ns (0 allocations: 0 bytes)
    3
"""
macro noelide(expr)
    out = postwalk(_refd, expr) |> esc
end



function testadd(x,y,z)
   a = x + y
   b = a + z
   c = b + a
   d = c + x
   return d
end

function testmul(x,y,z)
   a = x * y
   b = a * z
   c = z * x
   d = a * b
   return d
end

function testarith(x,y,z)
   a = x + y
   b = x * y
   c = z - b
   d = a / c
   return d
end


w32,x32,y32,z32 = Rational{Int32}.([1//12, -2//77, 3//54, -4//17]); q32 = Int32(1)//Int32(7);
u32,v32 = w32+z32, w32-z32

w64,x64,y64,z64 = Rational{Int64}.([1//12, -2//77, 3//54, -4//17]); q64 = Int64(1)//Int64(7);
u64,v64 = w64+z64, w64-z64

ply32 = Poly([w32, x32, y32, z32]);
ply64 = Poly([w64, x64, y64, z64]);
ply64w = Poly([u64, v64, w64, x64, y64, z64]);

a32,b32,c32,d32,e32,f32 = FastQ32.((w32,x32,y32,z32,u32,v32)); fastq32 = FastQ32(q32);
fastply32=Poly([a32,b32,c32,d32]);

a64,b64,c64,d64,e64,f64 = FastQ64.((w64,x64,y64,z64,u64,v64)); fastq64 = FastQ64(q64);
fastply64=Poly([a64,b64,c64,d64]);
fastply64w=Poly([a64,b64,c64,d64,e64,f64]);


m = [1//1 1//5 1//9 1//13; 1//2 1//6 1//10 1//14; 1//3 1//7 1//11 1//15; 1//4 1//8 1//12 1//16];
m32 = Rational{Int32}.(m);
m64 = Rational{Int64}.(m);
mfast32 = FastQ32.(m);
mfast64 = FastQ64.(m);


relspeed_arith32 =
    round( (@refd @belapsed testarith($x32,$y32,$z32)) /
           (@refd @belapsed testarith($a32,$b32,$c32)), digits=1);

relspeed_arith64 =
   round( (@refd @belapsed testarith($x64,$y64,$z64)) /
          (@refd @belapsed testarith($a64,$b64,$c64)), digits=1);


relspeed_add32 =
  round( (@refd @belapsed testadd($x32,$y32,$z32)) /
         (@refd @belapsed testadd($a32,$b32,$c32)), digits=1);

relspeed_add64 =
 round( (@refd @belapsed testadd($x64,$y64,$z64)) /
        (@refd @belapsed testadd($a64,$b64,$c64)), digits=1);


relspeed_mul32 =
 round( (@refd @belapsed testmul($x32,$y32,$z32)) /
        (@refd @belapsed testmul($a32,$b32,$c32)), digits=1);

relspeed_mul64 =
 round( (@refd @belapsed testmul($x64,$y64,$z64)) /
        (@refd @belapsed testmul($a64,$b64,$c64)), digits=1);


relspeed_ply32 =
 round( (@refd @belapsed polyval($ply32, $q32)) /
        (@refd @belapsed polyval($fastply32, $fastq32)), digits=1);

relspeed_ply64 =
 round( (@refd @belapsed polyval($ply64, $q64)) /
        (@refd @belapsed polyval($fastply64, $fastq64)), digits=1);
        
relspeed_ply64w =
 round( (@refd @belapsed polyval($ply64w, $q64)) /
        (@refd @belapsed polyval($fastply64w, $fastq64)), digits=1);


relspeed_matmul32 =
  round( (@refd @belapsed $m32*$m32) /
         (@refd @belapsed $mfast32*$mfast32), digits=1);

relspeed_matmul64 =
  round( (@refd @belapsed $m64*$m64) /
         (@refd @belapsed $mfast64*$mfast64), digits=1);


relspeed_matlu32 =
  round( (@refd @belapsed lu($m32)) /
         (@refd @belapsed lu($mfast32)), digits=1);

relspeed_matlu64 =
  round( (@refd @belapsed lu($m64)) /
         (@refd @belapsed lu($mfast64)), digits=1);
         

relspeed_matinv32 =
  round( (@refd @belapsed inv($m32)) /
         (@refd @belapsed inv($mfast32)), digits=1);

relspeed_matinv64 =
  round( (@refd @belapsed inv($m64)) /
         (@refd @belapsed inv($mfast64)), digits=1);

relspeeds = string(
"\n\n\t\trelative speeds\n",
"mul:   \t $relspeed_mul32 (32)\t $relspeed_mul64 (64)\n",
"muladd:\t $relspeed_arith32 (32)\t $relspeed_arith64 (64)\n",
"add:   \t $relspeed_add32 (32)\t $relspeed_add64 (64)\n",
"poly:  \t $relspeed_ply32 (32)\t $relspeed_ply64w (64)\n",
"matmul:\t $relspeed_matmul32 (32)\t $relspeed_matmul64 (64)\n",
"matlu: \t $relspeed_matlu32 (32)\t $relspeed_matlu64 (64)\n",
"matinv:\t $relspeed_matinv32 (32)\t $relspeed_matinv64 (64)\n");

print(relspeeds)

#=
println("\n\n\t\trelative speeds\n");
println("mul:   \t $relspeed_mul32 (32)\t $relspeed_mul64 (64)");
println("muladd:\t $relspeed_arith32 (32)\t $relspeed_arith64 (64)");
println("add:   \t $relspeed_add32 (32)\t $relspeed_add64 (64)");
println("poly:  \t $relspeed_ply32 (32)\t $relspeed_ply64w (64)");
println("matmul:\t $relspeed_matmul32 (32)\t $relspeed_matmul64 (64)");
println("matlu: \t $relspeed_matlu32 (32)\t $relspeed_matlu64 (64)");
println("matinv:\t $relspeed_matinv32 (32)\t $relspeed_matinv64 (64)");
=#
