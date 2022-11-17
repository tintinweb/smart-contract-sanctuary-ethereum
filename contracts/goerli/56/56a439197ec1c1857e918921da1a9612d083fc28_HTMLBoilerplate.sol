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