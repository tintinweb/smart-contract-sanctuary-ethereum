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