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