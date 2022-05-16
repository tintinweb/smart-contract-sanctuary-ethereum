/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library MathLib {

    uint8 constant Decimals = 8;
    int256 constant PI = 314159265;

    function sqrt(uint256 y) internal pure returns (uint256) {
      uint256 result;
      if (y > 3) {
          result = y;
          uint256 x = y / 2 + 1;
          while (x < result) {
              result = x;
              x = (y / x + x) / 2;
          }
      } else if (y != 0) {
          result = 1;
      }

      return result;
    }

    function abs(int256 x) internal pure returns (int256) {
        return x < 0 ? x*(-1) : x;
    }

    function max(int256 x, int256 y) internal pure returns (int256) {
        return x < y ? y : x;
    }

    function random(uint256 range, address caller, int256 seed_nonce) internal view returns (int256) {
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, caller, seed_nonce)));
        return int256(randomHash % range);
    } 
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = uint256(value);
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}

library Delaunay {

    int256 constant EPSILON = 1;

    function quickSort(uint256[] memory indices, int256[2][] memory vertices, int left, int right) internal pure {
        int i = left;
        int j = right;
        int mid = left + (right - left) / 2;
        if (i == j) return;
        int256 pivot = vertices[indices[uint(mid)]][0];
        while (i <= j) {
            while (vertices[indices[uint(i)]][0] > pivot) i++;
            while (pivot > vertices[indices[uint(j)]][0]) j--;
            if (i <= j) {
                (indices[uint(i)], indices[uint(j)]) = (indices[uint(j)], indices[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(indices, vertices, left, j);
        if (i < right)
            quickSort(indices, vertices, i, right);
    }

    function findSuperTriangle(int256[2][] memory vertices) internal pure returns (int256[2][3] memory) {
        int256[2][3] memory res;
        int256 minX = 100000000;
        int256 minY = 100000000;
        int256 maxX = -100000000;
        int256 maxY = -100000000;

        for (uint i=0; i<vertices.length; i++) {
            if (vertices[i][0] < minX) minX = vertices[i][0];
            if (vertices[i][0] > maxX) maxX = vertices[i][0];
            if (vertices[i][1] < minY) minY = vertices[i][1];
            if (vertices[i][1] > maxY) maxY = vertices[i][1];
        }

        int256 diffX = maxX - minX;
        int256 diffY = maxY - minY;
        int256 diffMax = diffX > diffY? diffX:diffY;
        int256 midX = minX + diffX/2;
        int256 midY = minY + diffY/2;

        res[0][0] = midX - 20 * diffMax;
        res[0][1] = midY - diffMax;
        res[1][0] = midX;
        res[1][1] = midY + 20 * diffMax;
        res[2][0] = midX + 20 * diffMax;
        res[2][1] = midY - diffMax;

        return res;
    }

    function circumcircle(int256[2][] memory vertices, uint256 i, uint256 j, uint256 k) internal pure returns(int256[6] memory) {
        int256 xc;
        int256 yc;
        int256 r;

        if (MathLib.abs(vertices[i][1] - vertices[j][1]) < 1) {
            int256 m2;
            int256 mx2;
            int256 my2;
            m2 = -( int256(10**4) * (vertices[k][0] - vertices[j][0]) / (vertices[k][1] - vertices[j][1]));
            mx2 = int256(10**4) * (vertices[j][0] + vertices[k][0]) / 2;
            my2 = int256(10**4) * ( vertices[j][1] + vertices[k][1]) / 2;
            xc =  int256(10**4) * (vertices[j][0] + vertices[i][0]) / 2;
            yc = m2 * (xc - mx2)/(int256(10**4)) + my2;
        } else if (MathLib.abs(vertices[j][1] - vertices[k][1]) < 1) {
            int256 m1;
            int256 mx1;
            int256 my1;
            m1 = -(int256(10**4) * ( vertices[j][0] - vertices[i][0]) / ( vertices[j][1] -  vertices[i][1]));
            mx1 = int256(10**4) * (vertices[i][0] + vertices[j][0]) / 2;
            my1 = int256(10**4) * (vertices[i][1] + vertices[j][1]) / 2;
            xc  = int256(10**4) * (vertices[k][0] + vertices[j][0]) / 2;
            yc = m1 * (xc - mx1)/(int256(10**4)) + my1;
        } else {
            int256 m1;
            int256 m2;
            int256 mx1;
            int256 mx2;
            int256 my1;
            int256 my2;
            m1 = -(int256(10**4) * (vertices[j][0] - vertices[i][0]) / (vertices[j][1] - vertices[i][1]));
            m2 = -(int256(10**4) * (vertices[k][0] - vertices[j][0]) / (vertices[k][1] - vertices[j][1]));
            mx1 = int256(10**4) * (vertices[i][0] + vertices[j][0]) / 2;
            mx2 = int256(10**4) * (vertices[j][0] + vertices[k][0]) / 2;
            my1 = int256(10**4) * (vertices[i][1] +  vertices[j][1]) / 2;
            my2 = int256(10**4) * (vertices[j][1] + vertices[k][1]) / 2;
            xc = (m1 * mx1 - m2 * mx2  + (int256(10**4)) * (my2 - my1)) / (m1 - m2);
            yc = MathLib.abs(vertices[i][1] - vertices[j][1]);
            yc = yc - MathLib.abs(vertices[j][1] - vertices[k][1]);
            yc = yc > 0 ? m1 * (xc - mx1)/(int256(10**4)) + my1 : m2 * (xc - mx2) /(int256(10**4))+ my2;
        }

        r = ((vertices[j][0]*(int256(10**4)) - xc) * (vertices[j][0]*(int256(10**4)) - xc) + (vertices[j][1]*(int256(10**4)) - yc) * (vertices[j][1]*(int256(10**4)) - yc))/(int256(10**4));

        return([int256(i), int256(j), int256(k), int256(xc), int256(yc), r]);
    }

    function triangulate(int256[2][] memory _vertices) internal pure returns (uint256, int256[] memory) {
        uint256 n = _vertices.length;
        int256[2][] memory vertices = new int256[2][](n+3);
        uint256[] memory indices = new uint256[](n);
        int256[6][] memory open   = new int256[6][](1000); 
        int256[6][] memory closed = new int256[6][](1000);
        int256[] memory res = new int256[](2000);
        // uint256 res_len = 0;
        uint256 open_len = 0;
        uint256 closed_len = 0;

        for(uint256 i=0; i<n; i++) {
            indices[i] = i;
            vertices[i] = _vertices[i];
        }

        quickSort(indices, _vertices, int(0), int(n-1));

        int256[2][3] memory st = findSuperTriangle(_vertices);
        vertices[n][0] = st[0][0];
        vertices[n][1] = st[0][1];
        vertices[n+1][0] = st[1][0];
        vertices[n+1][1] = st[1][1];
        vertices[n+2][0] = st[2][0];   
        vertices[n+2][1] = st[2][1];

        open[0] = circumcircle(vertices, n + 0, n + 1, n + 2);
        open_len++;

        for (uint i = indices.length; i > 0; i--) {
            int256[] memory edges = new int256[](500);
            uint256 edges_len = 0;
            uint256 c = indices[i-1];
            for (uint j = open_len; j>0; j--) {
                int256 dx = (int256(10**4))*vertices[c][0] - open[j-1][3];
                if ( (dx > 0) && (dx * dx > open[j-1][5] * int256(10**4)) ) {
                    closed[closed_len] = open[j-1];
                    closed_len++;
                    if(open_len > 0) {
                        open[j-1] = open[open_len-1];
                        open[open_len-1] = [int256(0), 0, 0, 0, 0, 0];
                        open_len--;
                    }
                    continue;
                }

                int256 dy = (int256(10**4))*vertices[c][1] - open[j-1][4];
                if ((dx * dx + dy * dy ) > open[j-1][5] * (int256(10**4)) + 95 ) { //  10^8 * EPSILON = 100000000 / 1048576.0 = 95.367
                    continue;
                }  

                edges[edges_len]   = open[j-1][0];
                edges[edges_len+1] = open[j-1][1];
                edges[edges_len+2] = open[j-1][1];
                edges[edges_len+3] = open[j-1][2];
                edges[edges_len+4] = open[j-1][2];
                edges[edges_len+5] = open[j-1][0];
                edges_len = edges_len + 6;

                if(open_len > 0) {
                    open[j-1] = open[open_len-1];
                    open[open_len-1] = [int256(0), 0, 0, 0, 0, 0];
                    open_len--;
                }
            }

            if(edges_len > 3) {
                for (uint256 jnd = edges_len+1; jnd>3; jnd = jnd-2) {
                    for (uint256 ind = jnd-2; ind>1; ind = ind -2) {
                        if ((edges[jnd-1-2] == edges[ind-1-2] && edges[jnd-2] == edges[ind-2]) || (edges[jnd-1-2] == edges[ind-2] && edges[jnd-2] == edges[ind-1-2])) {
                            edges[jnd-2]   = edges[edges_len - 1];
                            edges[jnd-1-2] = edges[edges_len - 2];
                            edges[ind-2]   = edges[edges_len - 3];
                            edges[ind-1-2] = edges[edges_len - 4];
                            edges[edges_len - 1] = 0;
                            edges[edges_len - 2] = 0;
                            edges[edges_len - 3] = 0;
                            edges[edges_len - 4] = 0;
                            edges_len = edges_len - 4;
                        }
                    }
                }
            }

            for (uint j = edges_len+1; j>1; j=j-2) {
                open[open_len] = circumcircle(vertices, uint256(edges[j-1-2]), uint256(edges[j-2]), c);
                open_len++;
            }
        }

        for (uint i = open_len; i > 0; i--) {
            closed[closed_len] = open[i-1];
            closed_len++;
        }

        open_len = 0;
        
        for (uint i = closed_len; i>0; i--) {
            if (closed[i-1][0] < int256(n) && closed[i-1][1] < int256(n) && closed[i-1][2] < int256(n)) {
                res[open_len] = closed[i-1][0];
                res[open_len+1] = closed[i-1][1];
                res[open_len+2] = closed[i-1][2];
                open_len = open_len + 3;
            }
        }

        return(open_len, res);
    }

    function generateColorShades(int256 R, int256 G, int256 B) internal pure returns(int256[3][3] memory) {
        int256[3][3] memory res;
        int256 max = MathLib.max(MathLib.max(R, MathLib.max(G, B)), 1);

        for (uint256 i = 1; i < 4; i++) {
            res[i%3][0] = R*int(255)*int(i)/(max*int(3));
            res[i%3][1] = G*int(255)*int(i)/(max*int(3));
            res[i%3][2] = B*int(255)*int(i)/(max*int(3));
        }

        return res;
    }

    function orientation(int256[2] memory p, int256[2] memory q, int256[2] memory r) public pure returns (uint) {
        // To find orientation of ordered triplet (p, q, r).
        // The function returns following values
        // 0 --> p, q and r are collinear
        // 1 --> Clockwise
        // 2 --> Counterclockwise
        int256 val = (q[1] - p[1]) * (r[0] - q[0]) - (q[0] - p[0]) * (r[1] - q[1]);    
        if (val == 0) return 0;  // collinear
        return (val > 0)? 1: 2; // clock or counterclock wise
    }

}


contract TriangleDraw {
    int256[2][] public bodyPoints = new int256[2][](100);
    uint256 public bp_len = 0;
    int256[2][] public convex = new int256[2][](100);
    uint256 public cv_len = 0;
    int256 public min_X = 100000000;
    int256 public max_X = 0;
 
    constructor() {
    }


    function generatePoint(uint256 point_count) public view returns(int256[2][] memory) {
        int256[2][] memory res = new int256[2][](point_count+bp_len);
        int256 nonce = 1121;

        if((max_X-min_X)<20)
            return res;

        for(uint i = 0; i < point_count; i++) {
            int256 pt_x = 0;
            int256 pt_y = 0;
            nonce = min_X + 10 + MathLib.random(uint256(max_X-min_X-20), msg.sender, nonce+int(i)*int(i));
            pt_x = nonce;
            // Find the pt_y scope
            int256 min_Y = 100000000;
            int256 max_Y = 0;

            for(uint j = 0; j < cv_len; j++) {
                if(convex[j][0] == convex[(j+1)%cv_len][0])
                    continue;
                if((convex[j][0]>=pt_x && convex[(j+1)%cv_len][0]<=pt_x ) || (convex[j][0]<=pt_x && convex[(j+1)%cv_len][0]>=pt_x ) ) {
                    // int256 temp_Y = convex[j][1] + (convex[(j+1)%cv_len][1]-convex[j][1])*(pt_x-convex[j][0])/(convex[j][0]-convex[(j+1)%cv_len][0]);
                    int256 temp_Y = convex[j][1] + (convex[(j+1)%cv_len][1]-convex[j][1])*(pt_x-convex[j][0])/(convex[(j+1)%cv_len][0]-convex[j][0]);
                    if(temp_Y < min_Y)
                        min_Y = temp_Y;
                    if(temp_Y > max_Y)
                        max_Y = temp_Y;
                }
            }

            pt_y = min_Y + 5 + MathLib.random(uint256(max_Y - min_Y-10), msg.sender, nonce+int(i)*int(i));

            res[i][0] = pt_x;
            res[i][1] = pt_y;
        }

        for(uint i = 0; i < bp_len; i++) {
            res[i+point_count][0] = bodyPoints[i][0];
            res[i+point_count][1] = bodyPoints[i][1];
        }

        return res;

    }

    function drawTriangles(uint256 point_count, int256 R, int256 G, int256 B) public view returns(string memory) {
        int256[2][] memory vertices = new int256[2][](bp_len + point_count);
        int256[] memory triangles;
        int256[3][3] memory colors;
        uint256 color_idx = 0;
        uint256 triangles_len;
        string memory svgStr;

        vertices = generatePoint(point_count);
        (triangles_len, triangles) = Delaunay.triangulate(vertices);
        colors = Delaunay.generateColorShades(R, G, B);

        for (uint i = 0; i < triangles_len; i += 3) {
            color_idx = (color_idx+1)%3;
            svgStr = string(
                abi.encodePacked(
                    svgStr,
                    '<polygon points="',
                    Strings.toString(vertices[uint256(triangles[i])][0]), ' ',
                    Strings.toString(vertices[uint256(triangles[i])][1]), ' ',
                    Strings.toString(vertices[uint256(triangles[i+1])][0]), ' ',
                    Strings.toString(vertices[uint256(triangles[i+1])][1]), ' ',
                    Strings.toString(vertices[uint256(triangles[i+2])][0]), ' ',
                    Strings.toString(vertices[uint256(triangles[i+2])][1]), '"',
                    ' fill="rgb(',
                    Strings.toString(colors[color_idx][0]), ',',
                    Strings.toString(colors[color_idx][1]), ',',
                    Strings.toString(colors[color_idx][2]),
                    ')" stroke="black" stroke-width="2"></polygon>'
                )
            );
        }

        svgStr = string(
            abi.encodePacked(
                '<svg width="1000" height="1000" version="1.1" xmlns="http://www.w3.org/2000/svg">',
                '<g class="svg">',
                svgStr,
                '</g>',
                '</svg>'
            )
        );

        return svgStr;

    }

}