// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./core/HTMLBoilerplate.sol";
import "./core/Gen.sol";
import "./sdf/Layers.sol";
import "./sdf/Scenes.sol";
import "./sdf/Layout.sol";
import "./lib/ListUtils.sol";
import "./generative/Puzzle.sol";
import "./core/Vectors.sol";
library GenerativeArt {
    using Gen for string;
    using Gen for Gen.Variable;
    using Vectors for string;
    using Layers for Layers.Layer;
    using ListUtils for string[];
    using Vectors for string;

    function vertexShader() public pure returns (string memory) {
        return "attribute vec4 aVertexPosition;\\n"
            "void main() {\\n"
            "gl_Position = aVertexPosition;\\n"
            "}\\n";
    }
    
    function fragmentShader() public pure returns (string memory) {    
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
    }  

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

    function generate() public pure returns (string memory) {
        string memory m = HTMLBoilerplate.withShaders(
            vertexShader(),
            fragmentShader());
        return m;
   
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import '../lib/Base64.sol';

library HTMLBoilerplate {
    
    string constant BOILER_PLATE_A =  "const vertexShader = loadShader(gl, gl.VERTEX_SHADER, vsSource);\n"
            "const fragmentShader = loadShader(gl, gl.FRAGMENT_SHADER, fsSource);"
            "const shaderProgram = gl.createProgram();\n"
            "gl.attachShader(shaderProgram, vertexShader);\n"
            "gl.attachShader(shaderProgram, fragmentShader);\n"
            "gl.linkProgram(shaderProgram);\n"
            "return shaderProgram;\n"
            "}\n\n"

            "function loadShader(gl, type, source) {\n"
            "const shader = gl.createShader(type);\n"
            "gl.shaderSource(shader, source);\n"
            "gl.compileShader(shader);\n"                      
            "if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {\n"
            "alert(`An error occurred compiling the shaders: ${gl.getShaderInfoLog(shader)}`);\n"
            "gl.deleteShader(shader);\n"
            "return null;\n"
            "}"
            "return shader;\n"
            "}\n\n"


            "function initBuffers(gl) {\n"
            "  const positionBuffer = gl.createBuffer();\n"
            "  gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);\n"
            "  const positions = [\n"
            "  1.0,  1.0,\n"
            "  -1.0,  1.0,\n"
            "   1.0, -1.0,\n"
            "  -1.0, -1.0,\n"
            "  ];\n"
            "  gl.bufferData(gl.ARRAY_BUFFER,\n"
            "    new Float32Array(positions),\n"
            "    gl.STATIC_DRAW);\n"
            
            "  return {\n"
            "   position: positionBuffer,\n"
            "  };\n"
            "}\n\n"

            // draw scene applies everything
            "function drawScene(gl, programInfo, buffers) {\n"
            "  gl.clearColor(0.0, 0.0, 0.0, 1.0);\n"
                "  gl.clearDepth(1.0);\n"
           

            // set the attribute
                "{\n"
                "    const numComponents = 2;\n"
                    "    const type = gl.FLOAT;\n"
                    "    const normalize = false;\n"
                    "    const stride = 0;\n"
                    "    const offset = 0;\n"
                    "    gl.bindBuffer(gl.ARRAY_BUFFER, buffers.position);\n"
                    "    gl.vertexAttribPointer(\n"
                                                "        programInfo.attribLocations.vertexPosition,\n"
                                                "        numComponents,\n"
                                                "        type,\n"
                                                "        normalize,\n"
                                                "        stride,\n"
                                                "        offset);\n"
                    "    gl.enableVertexAttribArray(\n"
                                                    "        programInfo.attribLocations.vertexPosition);\n"
                    "  }\n"

            // set the uniforms...


                "  gl.useProgram(programInfo.program);\n"
            
            "gl.uniform2fv(programInfo.uniformLocations.res, [window.innerWidth, window.innerHeight]);\n"
            
            "{\n"
            "   const offset = 0;\n"
                "    const vertexCount = 4;\n"
                    "    gl.drawArrays(gl.TRIANGLE_STRIP, offset, vertexCount);\n"
            "}\n"
            "requestAnimationFrame(render);"
            "}\n\n"
            "const START_TIME = new Date().getTime();\n"
            "var gl, programInfo, buffers, canvas;\n"


            "function main() {\n"
            "  const fO = document.querySelector(\"foreignObject\");\n"
            "  canvas = fO.querySelector(\"#glCanvas\");\n"
            "  canvas.width = window.innerWidth;\n"
            "  canvas.height = window.innerHeight;\n"
            "  gl = canvas.getContext(\"webgl\");\n"
            "  const shaderProgram = initShaderProgram(gl);"

            "  programInfo = {\n"
            "    program: shaderProgram,"
            "    attribLocations: {"
            "      vertexPosition: gl.getAttribLocation(shaderProgram, 'aVertexPosition'),"
            "    },"
            "    uniformLocations: {\n"
            "      res: gl.getUniformLocation(shaderProgram, 'res'),\n"
            "      time: gl.getUniformLocation(shaderProgram, 'time'),\n"
            "    },"
            "  };"
            "  buffers = initBuffers(gl);"
            "  drawScene(gl, programInfo, buffers);\n"
            "  window.addEventListener(\"resize\", render);\n"
            "}"

            "function render() {"
            "  let time = new Date().getTime() - START_TIME;"
            "  console.log(time);"
            "  canvas.width = window.innerWidth;\n"
            "  canvas.height = window.innerHeight;\n"
            "  gl.uniform1f(programInfo.uniformLocations.time, time/1000);\n"
            "gl.uniform2fv(programInfo.uniformLocations.res, [window.innerWidth, window.innerHeight]);\n"

            "  {\n"
            "   const offset = 0;\n"
            "   const vertexCount = 4;\n"
            "   gl.drawArrays(gl.TRIANGLE_STRIP, offset, vertexCount);\n"
            "}\n"
            "}"
            "window.onload = main;";

    function boilerPlate(
        string memory vertexShader,
        string memory fragmentShader) public pure returns (string memory) {

        string memory x = string(
          abi.encodePacked(
            // initShader program loads the shader code (doesnt compile)
            "function initShaderProgram(gl) {\n"
            "const vsSource = \"", vertexShader, "\";\n"
            "const fsSource = \"", fragmentShader, "\";\n",
            BOILER_PLATE_A
            )
        );
        return x;
    }

    function withShaders(
        string memory vertexShader,
        string memory fragmentShader) public pure returns (string memory) {
        string memory x = string(
            abi.encodePacked(
              "data:image/svg+xml;base64,",
              Base64.encode(
                bytes(
                  abi.encodePacked(
                    "<svg id=\"container\" xmlns=\"http://www.w3.org/2000/svg\">\n",              
                    "<foreignObject x=\"0\" y=\"0\" width=\"100%\" height=\"100%\">"
                    "<span xmlns=\"http://www.w3.org/1999/xhtml\">\n"
                    "<canvas id=\"glCanvas\"/>\n"
                    "</span>"
                    "</foreignObject>"
                     "<script type=\"text/javascript\">\n",
                    "//<![CDATA[\n",
                    boilerPlate(vertexShader, fragmentShader),
                    "\n//]]>\n"
                    "</script>\n"
                    "</svg>\n"
                                   )))));
        return x;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "../lib/Conversion.sol";

library Vectors {
    function vec2(
        string memory r,
        string memory g)
        public pure returns (string memory){
        return string(abi.encodePacked("vec2(", r, ",", g, ")"));
    }

    function vec2(
        int r,
        int g)
        public pure returns (string memory){
        return string(
            abi.encodePacked(
                "vec2(", 
                Conversion.int2float(r), ",", 
                Conversion.int2float(g), ")"));
    }

    function vec3(
        string memory r,
        string memory g,
        string memory b)
        public pure returns (string memory){
        return string(abi.encodePacked("vec3(", r, ",", g, ",", b, ")"));
    }

    function vec3(
        int r,
        int g,
        int b)
        public pure returns (string memory){
        return string(
            abi.encodePacked(
                "vec3(", 
                Conversion.int2float(r), ",", 
                Conversion.int2float(g), ",",
                Conversion.int2float(b), ")"
                ));
    }

    function vec4(
        string memory r,
        string memory g,
        string memory b,
        string memory a)
        public pure returns (string memory){
        return string(abi.encodePacked("vec4(", r, ",", g, ",", b, ",", a, ")"));
    }

    function vec4(
        int r,
        int g,
        int b,
        int a)
        public pure returns (string memory){
        return string(
            abi.encodePacked(
                "vec4(", 
                Conversion.int2float(r), ",", 
                Conversion.int2float(g), ",",
                Conversion.int2float(b), ",",
                Conversion.int2float(a), ")"
                ));
    }

    // following extract fields from vectors (x,y,z,w)
    function getX(string memory a) public pure returns (string memory) {
        return _extract(a, "x");
    }

    function getY(string memory a) public pure returns (string memory) {
        return _extract(a, "y");
    }

    function getZ(string memory a) public pure returns (string memory) {
        return _extract(a, "z");
    }


    function getW(string memory a) public pure returns (string memory) {
        return _extract(a, "w");
    }

    function _extract(string memory a, string memory field) private pure returns (string memory) {
        return string(abi.encodePacked(
            a, ".", field
        ));
    }

}

pragma solidity ^0.8.13;

import "../lib/ListUtils.sol";

/* 
* 
* Grid: [SHAPE SHAPE SHAPE SHAPE SHAPE] -----_-_-_---->  Partitioned Grid: [SHAPE SHAPE] [SHAPE SHAPE]
* 
* Combine adjacent pieces to form several groups of pieces that can be invididually
* "smooth unioned" and then layered in sequence.
**/

library Puzzle {
    
    using ListUtils for string[];
    using ListUtils for int8[];

    /**
    * @notice the grid is a 1-dimensional array though it really describes a 2D grid
     */
    function partitionAndCombine(string[] memory grid, uint size, int8[] memory program) public  pure returns (string[][] memory) {
        
        uint numPartitions = grid.length - program.count(-1);
        string[][] memory partitions = new string[][](numPartitions);
        // we need to figure out how many partitions there will be...
        uint pidx = 0;

        for (uint idx=0; idx < program.length; idx++) {
            int8 pieceType = program[idx % program.length];
            if (pieceType == -1) {
                // we skip this piece altogether
                continue;
            }
            uint[] memory pieceIndices = getPieceIndices(pieceType, idx, size);
            string[] memory piece = ListUtils.byIndices(grid, pieceIndices);
            partitions[pidx++] = piece;
        }
        return partitions;
    }

    /** 
    @notice Each piece has a type which specifies how it will combine the pieces
    * from the grid into a new piece.
    * This function simply returns the "new" combined indices for an index
     */
    function getPieceIndices(int8 pieceType, uint index, uint size) public pure returns (uint[]memory) {
        
        if (pieceType == 1) {
            /**  
                OO
             */
            uint [] memory piece = new uint[](2);
            piece[0] = index;
            piece[1] = index + size;
            return piece;
        } else if (pieceType == 2) {
            /**  
                0
                0
             */
            uint [] memory piece = new uint[](2);
            piece[0] = index;
            piece[1] = index + 1;
            return piece;
        } else if (pieceType == 3) {
            /**  
                0 0 
                0 0
             */
            uint [] memory piece = new uint[](4);
            piece[0] = index;
            piece[1] = index + 1;
            piece[2] = index + size;
            piece[3] = index + size + 1;
            return piece;
        } else if (pieceType == 4) {
            /**  
                0 0 
                0
             */
            uint [] memory piece = new uint[](3);
            piece[0] = index;
            piece[1] = index + 1;
            piece[2] = index + size;
            return piece;
        } else if (pieceType == 5) {
            /**  
                  0
                0 0 0
             */
            uint [] memory piece = new uint[](3);
            piece[0] = index;
            piece[1] = index + 1;
            piece[2] = index + size;
            return piece;
        } else if (pieceType == 6) {
            /**    
                0 0 0
                  0
             */
            uint [] memory piece = new uint[](3);
            piece[0] = index;
            piece[1] = index - 1;
            piece[2] = index + size;
            return piece;
        } else {
            /**
                O
             */
            uint [] memory piece = new uint[](1);
            piece[0] = index;
            return piece;
        }
    }

    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
   Conversion library from unsigned integer to string
 */
library Conversion {

    function int2float(int i) internal pure returns (string memory) {
        //     3 -> 0.003 
        //    30 -> 0.03
        //   300 -> 0.30
        //  3000 -> 3.0
        // 30000 -> 30
        //uint decimalSize = 3;
        if (i == 0) {
            return "0.0";
        }
        string memory str = uint2str(abs(i));
        uint256 len = strlen(str);
        if (len <= 3) {
            return string(abi.encodePacked(
                i < 0 ? "-" : "", "0.", repeat("0", 3 - len), str));
        } else {
            return string(abi.encodePacked(
                i < 0 ? "-" : "",
                substring(str, 0, len - 3), ".",
                substring(str, len - 3, len)
            ));
        }
    }

    function substring(string memory str, uint startIndex, uint endIndex) public pure returns (string memory ) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    function repeat(string memory a, uint256 repeats) public pure returns (string memory) {
        string memory b = "";
        for (uint256 i=0; i < repeats; i++) {
            b = string(
                abi.encodePacked(
                    b, a
                ));
        }
        return b;
    }

    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    } 

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            bstr[k] = bytes1((48 + uint8(_i - _i / 10 * 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    function abs(int x) private pure returns (uint) {
        return x >= 0 ? uint(x) : uint(-x);
    }       
}

pragma solidity ^0.8.13;

library ListUtils {

     function prune(string[] memory list, uint256[] memory prunes) public pure returns (string [] memory) {
        string [] memory pruned = new string[](list.length - prunes.length);
        uint c = 0;
        for (uint i=0; i < list.length && c < pruned.length; i++) {
            bool found = false;
            for (uint j=0; j < prunes.length; j++) {
                if (i == prunes[j]) {
                    found = true;
                    break;
                }
            }
            // if its in the list we need to not allow it
            if (!found) {
                pruned[c++] = list[i];
            }
        }
        return pruned;
    }

    function byIndices(
        string[] memory list, 
        uint[] memory indices) 
    public pure returns (string [] memory) {
        string [] memory filtered = new string[](indices.length);
        for (uint i=0; i < indices.length; i++) {
            filtered[i] = list[indices[i] % list.length];
        }
        return filtered;
    }

    function count(
        int8[] memory list,
        int s) public pure returns (uint) {
        
        uint c = 0;
        for (uint i=0; i < list.length; i++) {
            if (list[i] == s) {
                c++;
            }
        }
        return c;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "../core/Gen.sol";
import "./SDF.sol";

library Layers {
    using Gen for string;

    struct Layer {
        string sdf;
        string blur;
        string color;
        bool intersect;
        string intersectionColor;
    }

    function create(
        string memory sdf) 
    public pure returns (Layer memory) {
        return Layer(
            sdf,
            "0.006",
            Gen.black,
            false,
            ""
        );
    }

    function create(
        string memory sdf, 
        string memory blur, 
        string memory color) 
    public pure returns (Layer memory) {
        return Layer(
            sdf,
            blur,
            color,
            false,
            ""
        );
    }

    function withColor(Layer memory layer, string memory color) public pure returns  (Layer memory) {
        layer.color = color;
        return layer;
    }

    function withBlur(Layer memory layer, string memory blur) public pure returns  (Layer memory) {
        layer.blur = blur;
        return layer;
    }

    function withIntersection(Layer memory layer, string memory color) public pure returns  (Layer memory) {
        layer.intersect = true;
        layer.intersectionColor = color;
        return layer;
    }

    function newLayer(
        string memory sdf, 
        string memory blur, 
        string memory color,
        bool intersection,
        string memory intersectionColor) 
    public pure returns (Layer memory) {
        return Layer(
            sdf,
            blur,
            color,
            intersection,
            intersectionColor
        );
    }

    function draw(Layer memory layer, string memory background) public pure returns( string memory) {
        return Gen.mix(
            background,
            layer.color,
                Gen.smoothstep(
                layer.blur,
                "0.0", //layer.blur.mult(layer.sdf),
                layer.sdf)
        );
    }

    function draw(Layer[] memory layers, string memory background) public pure returns (string memory) {
        string memory unionSoFar = "10000.0";
        for (uint256 i=0; i < layers.length; i++) {
            background = draw(layers[i], background);
            if (i > 0 && layers[i].intersect) {
                background = draw(Layer(
                    SDF.intersection(unionSoFar, layers[i].sdf),
                    layers[i].blur,
                    layers[i].intersectionColor,
                    false,
                    ""
                ), background);
            }
            unionSoFar = SDF.union(unionSoFar, layers[i].sdf);
        }
        return background;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './SDF.sol';
import '../core/Vectors.sol';
import '../lib/Conversion.sol';

library Layout {
    /**
    @notice Creates an NxM grid of rectangles w/ parametric spacing
    *  centered.
     */
    function gridRect(int rows, int cols, int w, int h, int[2]memory spacing, string memory rotation, int round) public pure returns (string [] memory) {
        string[] memory rects  = new string[](uint(rows*cols));
        int x = -(w+spacing[0])*cols/2 + w;
        int y = -(h+spacing[1])*rows/2 + h;
        //int alt = altOffset ? w/2 : int(0);
        for (int i=0; i < rows; i++) {
            for (int j=0; j < cols; j++) {
                rects[uint(i*cols + j)] =  _rect(
                    uint(i*cols + j), 
                    x  + i*(w+spacing[0]),
                    y + (i % 2)*h + j*(h+spacing[1]),
                    w,
                    h,
                    rotation,
                    round
                    );
            }
        }
        return rects;
    }

    function gridRect(int rows, int cols, int w, int h, int spacing, int[] memory widths, int[] memory heights) public pure returns (string [] memory) {
        string[] memory rects  = new string[](uint(rows*cols));
        int x = -(w+spacing)*cols/2 + w;
        int y = -(h+spacing)*rows/2 + h;
        for (int i=0; i < rows; i++) {
            for (int j=0; j < cols; j++) {
                uint idx = uint(i*cols + j);
                rects[idx] = _rect(
                    idx, 
                    x + i*(w+spacing),
                    y + j*(h+spacing),
                    widths,
                    heights,
                    0
                    );
            }
        }
        return rects;
    }

    function _rect(uint idx, int x, int y, int[] memory widths, int [] memory heights, int rotation) public pure returns (string memory) {
        return SDF.rect(
            Vectors.vec2(
                x, y
            ),
            Vectors.vec2(widths[idx%widths.length], heights[idx%heights.length]),
            "vec4(.1, .1, .1, .1)",
            Conversion.int2float(rotation)
            ) ;
    }

    function _rect(uint idx, int x, int y, int w, int h, string memory rotation, int r)  public pure returns (string memory) {
        return SDF.rect(
            Vectors.vec2(
                x, y
            ),
            Vectors.vec2(w, h),
            Vectors.vec4(r, r, r, r),
            rotation
            ) ;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "../core/Gen.sol";
import "../lib/Conversion.sol";

library SDF {
    function circle(
        string memory position, 
        string memory radius) public pure returns (string memory) {    
        return string(
            abi.encodePacked(
                "length(uv - ", position, ") - ", radius      
            )
        );
    }

    function circle(
        string memory position, 
        int  radius) public pure returns (string memory) {    
        return string(
            abi.encodePacked(
                "length(uv - ", position, ") - ", Conversion.int2float(radius)
            )
        );
    }
    
    function rect(
        string memory position, 
        string memory dimensions, 
        string memory corner,
        string memory rotation) public pure returns (string memory) {    
        return string(
            abi.encodePacked(
                "sdfRect(uv - ", position, ", ", dimensions, ", ", corner, ", ", rotation, ")"      
            )
        );
    }
    
    function union(string memory a, string memory b) public pure returns (string memory) {
        return Gen.primitive("min", a, b);
    }

    function subtraction(string memory a, string memory b) public pure returns (string memory) {
        return Gen.primitive("max", string(abi.encodePacked("-", a)), b);
    }

    function intersection(string memory a, string memory b) public pure returns (string memory) {
        return Gen.primitive("max", a, b);
    }

    
    function _sdfRect() private pure returns (string memory) {
        return Gen.gen(
            Gen.Function(
                "sdfRect",
                "float",
                "vec2 p, vec2 b, vec4 r, float angle",

                // body
                "r.xy = (p.x>0.0)?r.xy : r.zw;\\n"
                "r.x  = (p.y>0.0)?r.x  : r.y;\\n"
                "p *= rotate2D(angle);\\n"
                "vec2 q = abs(p)-b+r.x;\\n"
                "return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r.x;\\n"
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "../core/Gen.sol";
import "../lib/Conversion.sol";

library Scenes {
    enum OperationType{ UNION, SMOOTH_UNION}

    struct Scene {
        string[] sdfs;
    }

    // a scene is a collection of SDFs along w/ a way to operate on them
    // can use a scene to calcutate the sdf/index/mix
    // the goal is to smooth union multiple SDFs and return vec3(sdf,index,mix)
    function create(Scene memory scene,  OperationType operationType, string memory name, string memory k) public pure returns (Gen.Function memory) {
        string memory body = string(abi.encodePacked(
            "vec3 scene = vec3(sdf0, 0.0, 0.0);\\n"
            "float mAccumulator = 0.0;\\n"
            "float d1 = 0.0;\\n"
            "float d2 = 0.0;\\n"
            "float k=", k, ";\\n"
            "float h=0.0;\\n"
            "float m=0.0;\\n"
            "float s=0.0;\\n"
        ));

        for (uint256 i=1; i < scene.sdfs.length; i++) {
            if (operationType == OperationType.UNION) {
                body = string(abi.encodePacked(
                    body,
                    union(i)
                ));
            } else if (operationType == OperationType.SMOOTH_UNION) {
                body = string(abi.encodePacked(
                    body,
                    smoothUnion(i)
                ));
            }
        }
        body = string(abi.encodePacked(
            body,
            "return scene;\\n"
        ));

        // return the function as we need to be able to call it
        return Gen.Function(
            name,
            "vec3",
            getDefinitionParams(scene.sdfs.length),
            body
        );
    }  

    function smoothUnion(uint256 i) public pure returns (string memory) {
        string memory body = string(abi.encodePacked(
            "d2 = scene.x;\\n",
            "d1 = sdf", Conversion.uint2str(i), ";\\n"
            "h = max(k - abs(d1-d2), 0.0)/k;\\n"
            "m = pow(h, 1.5)*0.5;\\n"
            "s = m*k*(1.0/1.5);\\n"
            "mAccumulator += h*h*", Conversion.uint2str(i), ".0;\\n"
            "if (d1 < scene.x) {\\n"
            " scene = vec3(d1 - s,", Conversion.uint2str(i), ".0, mAccumulator + m);"
            "}\\n"
            "else {\\n"
            "  scene = vec3(d2 - s, scene.y, mAccumulator + m);\\n"
            "}\\n"
        ));
        
        return body;
    }

    function union(uint256 i) public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "if (scene.x > sdf", Conversion.uint2str(i), ") {\\n"
                "  scene.x = sdf", Conversion.uint2str(i), ";\\n"
                "  scene.y = ", Conversion.uint2str(i), ".0;\\n"
               "}\\n"));
    }

    function gen(string [] memory sdfs, Gen.Function memory func) public pure returns (string memory) {
        return string(abi.encodePacked(
            func.name, "(", getCallParams(sdfs), ")"
        ));
    }

    function gen(Scene memory scene, Gen.Function memory func) public pure returns (string memory) {
        return string(abi.encodePacked(
            func.name, "(", getCallParams(scene.sdfs), ")"
        ));
    }

    function getCallParams(string [] memory sdfs) private pure returns (string memory) {
        string memory joined = "";
        for (uint256 i=0; i < sdfs.length; i++) {
            joined = string(abi.encodePacked(
                joined, sdfs[i], (i < sdfs.length-1 ? "," : "")
            ));
        }
        return joined;
    }
    function getDefinitionParams(uint256 len) private pure returns (string memory) {
        string memory joined = "";
        for (uint256 i=0; i < len; i++) { 
            joined = string(abi.encodePacked(
                joined, "float sdf", Conversion.uint2str(i), (i < len-1 ? "," : "")
            ));
        }
        return joined;
    }
}