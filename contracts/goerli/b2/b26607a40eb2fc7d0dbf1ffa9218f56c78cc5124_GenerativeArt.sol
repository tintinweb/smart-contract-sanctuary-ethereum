// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
//import "./core/HTMLBoilerplate.sol";
import "./core/Gen.sol";
//import "./sdf/Layers.sol";
//import "./sdf/Scenes.sol";
//import "./sdf/Layout.sol";
//import "./lib/ListUtils.sol";
//import "./generative/Puzzle.sol";
//import "./core/Vectors.sol";
library GenerativeArt {
    /*
    using Gen for string;
    using Gen for Gen.Variable;
    using Vectors for string;
    using Layers for Layers.Layer;
    using ListUtils for string[];
    using Vectors for string;
    */

    function vertexShader() public pure returns (string memory) {
        return "attribute vec4 aVertexPosition;\\n"
            "void main() {\\n"
            "gl_Position = aVertexPosition;\\n"
            "}\\n";
    }
    
    function fragmentShader() public pure  returns (string memory) {  
        return Gen.add("5.0", "1.0");
        /*
        string[] memory sdfs = Layout.gridRect(
                4, 4, 180, 180, [int(145), int(195)], "0.0", 180);
        
        string[3] memory colors = [
            "vec4(.86, 0.77, 0.77, 1.0)", 
            "vec4(0.914, 0.85, 0.92, 1.0)", 
            "vec4(0.9, 0.95, 0.94, 1.0)"
            ];

        string[][] memory partitioned = Puzzle.partitionAndCombine(
            sdfs, 4, getAlgo());

        Layers.Layer[] memory layers = new Layers.Layer[](partitioned.length);
        Gen.Variable[] memory variables = new Gen.Variable[](partitioned.length);
        Gen.Function[] memory functions = new Gen.Function[](partitioned.length);

        for (uint i=0; i < partitioned.length; i++) {
            // setup the scene with "smooth union" and throw in the sdfs into it
            functions[i] = Scenes.create(
                Scenes.Scene(partitioned[i]), 
                Scenes.OperationType.SMOOTH_UNION, 
                string(abi.encodePacked("scene", Conversion.uint2str(i))),
                ".156"
                );
        
            // save the outputted SDF values to a variable so 
            // that we don't repeat code/recompute in GPU
            variables[i] = Gen.Variable(
                string(abi.encodePacked("sceneSDF", Conversion.uint2str(i))),
                 "vec3", 
                Scenes.gen(partitioned[i], functions[i]));

        }

        for (uint i=0; i < partitioned.length; i++) {
            string memory sdf = variables[i].name.getX();
            string memory mixAvg = variables[i].name.getZ();
            // create a layer

            string memory color;
            string memory ss;
            {
                ss = Gen.smoothstep("-0.15", "0.056", sdf);
                color = Gen.mix(
                    colors[i%colors.length],
                     "vec4(0.4, 0.35, 0.98, 1.0)",
                    ss
                );
            }
            layers[i] = Layers.create(sdf)
                .withColor(
                    Gen.rand().mult(".068").mult(ss).add(
                        Gen.mix(
                            color,
                            Gen.mix(
                                Gen.black,
                                "vec4(1.0, 0.90, 0.9, 1.0)",
                                Gen.mult(Gen.uv.getY(), Gen.uv.getX())),
                        mixAvg.pow(".5").mult(".8")))
                )
                .withBlur("0.008");
            if (i % 3 > 0) {
                layers[i] = layers[i].withIntersection(
                    Gen.rand().mult(".039").add(
                        Gen.mix(
                            "vec4(.96, .84, .87, 1.0)",
                            "vec4(.86, .86, .93, 1.0)",
                            Gen.sub(Gen.uv.getY(), Gen.uv.getX())
                        )
                    )
                );
            }      
        }

        string memory grad = Gen.mix(
            Gen.black,
            "vec4(.09, .09, .12, 1.0)",
            Gen.uv.getX().mult(Gen.uv.getY())
        );

        return Gen.fragColor(
            Layers.draw(layers, grad.add(Gen.rand().mult("0.06"))), 
            functions, variables);
            */
    }  
/*
    function getAlgo() private pure returns (int8[] memory) {
        int8[] memory algo = new int8[](16);
        algo[0] = -1;
        algo[1] = 4;
        algo[2] = 6;            
        algo[3] = 6;    
        algo[4] = 3;    
        algo[5] = 4;
        algo[6] = 4;
        algo[7] = -1;
        algo[8] = -1;
        algo[9] = -1;
        algo[10] = -1;
        algo[11] = 2;
        algo[12] = -1;
        algo[13] = -1;
        algo[14] = -1;
        algo[15] = 0;
        return algo;
    }
    */

/*
    function generate() public  returns (string memory) {
        
        string memory m = HTMLBoilerplate.withShaders(
            "a",
            "b");
        return m;
   
    }
    */
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Gen {

    uint8 constant public DECIMAL_PLACES = 3; // 3 ==> 0.003 , 30 => 0.03, 300 => 0.3 => 3000 => 3

    string constant public time = "time";
    string constant public x = "gl_FragCoord.x";
    string constant public y = "gl_FragCoord.y";
    string constant public xy = "gl_FragCoord.xy";
    string constant public res = "res";
    string constant public _uv = "((2.0*gl_FragCoord.xy-res)/res.y)";
    string constant public uv = "uv";
    string constant black = "vec4(0.0, 0.0 , 0.0, 1.0)";
    string constant white = "vec4(1.0, 1.0 , 1.0, 1.0)";

    struct Variable {
        string name;
        string glType;
        string value;
    }

    struct Function {
        string name;
        string returnType;
        string params;
        string body;
    }
    
    function add(string memory a, string memory b) public pure returns (string memory) {
       return string(abi.encodePacked(a, "+", b));
    }

    function sub(string memory a, string memory b) public pure returns (string memory){
        return string(abi.encodePacked(a, "-", b));
    }

    function mult(string memory a, string memory b) public pure returns (string memory){
        return string(abi.encodePacked(a, "*", b));
    }

    function div(string memory a, string memory b) public pure returns (string memory){
        return string(abi.encodePacked(a, "/", b));
    }

    function primitive(string memory funcName, string memory a) public pure returns (string memory) {
        return string(abi.encodePacked(funcName, "(", a, ")"));
    }

    function primitive(string memory funcName, string memory a, string memory b) public pure returns (string memory) {
        return string(abi.encodePacked(funcName, "(", a, ",", b, ")"));
    }

    function primitive(string memory funcName, string memory a, string  memory b, string memory c) public pure returns (string memory) {
        return string(abi.encodePacked(funcName, "(", a, ",", b, ",", c, ")"));
    }

    function mod(string memory a, string memory b) public pure returns (string memory){
        return primitive("mod", a, b);
    }

    function pow(string memory a, string memory b) public pure returns (string memory){
        return primitive("pow", a, b);
    }

    function length(string memory a) public pure returns (string memory){
        return primitive("length", a);
    }

    function fwidth(string memory a) public pure returns (string memory) {
        return primitive("fwidth", a);
    }

    function sin(string memory a) public pure returns (string memory) {
        return primitive("sin", a);
    }

    function cos(string memory a) public pure returns (string memory) {
        return primitive("cos", a);
    }

    function atan(string memory a, string memory b) public pure returns (string memory) {
        return primitive("atan", a, b);
    }

    function smoothstep(string memory a, string memory b, string memory c) public pure returns (string memory) {
        return primitive("smoothstep", a, b, c);
    }

    function mix(string memory a, string memory b, string memory c) public pure returns (string memory) {
        return primitive("mix", a, b, c);
    }

    function rand() public pure returns (string memory) {
        return "fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453)";
    }

    function fragColor(string memory a) public pure returns (string memory){
        Function[] memory functions = new Function[](0);
        Variable[] memory variables = new Variable[](0);
        return fragColor(a, functions, variables);
    }

    function fragColor(
        string memory a, 
        Function[] memory functions, 
        Variable[] memory variables) public pure returns (string memory){
        return string(
            abi.encodePacked(
                "precision highp float;\\n"
                "uniform float time;\\n"
                "uniform vec2 res;\\n",
                SDF_FUNCTIONS,
                gen(functions),
                "void main() {\\n",
                "vec2 uv = ", _uv, ";\\n",
                generateVariables(variables),
                "gl_FragColor = ", a, ";\\n}"));
    }

    function generateVariables(Variable[] memory variables) public pure returns (string memory) {
        string memory code = "";
        for (uint256 i=0; i < variables.length; i++) {
            code = string(abi.encodePacked(
                code,
                variables[i].glType, " ", variables[i].name, " = ", variables[i].value, ";\\n"));
        }
        return code;
    }

    /**
     Functions for generating different types (functions & variables)
     */
    function gen(Function memory func) public pure returns (string memory) {
        return string(
            abi.encodePacked(
                func.returnType, " ", func.name, "(", func.params, ") {\\n",
                func.body,
                "\\n",
                "}\\n"
            )
        );
    }
  
    function gen(Function[] memory func) public pure returns (string memory) {
        string memory code = "";

        for (uint256 i=0; i < func.length; i++) {
            code = string(abi.encodePacked(code, gen(func[i]), "\\n"));
        }
        return code;
    }

    string constant public SDF_FUNCTIONS = "mat2 rotate2D(float angle) {\\n"
    "return mat2(\\n"
    "cos(angle), -sin(angle),sin(angle),cos(angle));\\n"
    "}\\n"
    "float sdfRect(vec2 p, vec2 b, vec4 r, float angle) {\\n"
    "r.xy = (p.x>0.0)?r.xy : r.zw;\\n"
    "r.x  = (p.y>0.0)?r.x  : r.y;\\n"
    "p *= rotate2D(angle);\\n"
    "vec2 q = abs(p)-b+r.x;\\n"
    "return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r.x;\\n"
    "}\\n";
}