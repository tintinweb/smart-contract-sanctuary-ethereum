/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    using Strings for int256;
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

        // int256 x1 = vertices[i][0];
        // int256 y1 = vertices[i][1];
        // int256 x2 = vertices[j][0];
        // int256 y2 = vertices[j][1];
        // int256 x3 = vertices[k][0];
        // int256 y3 = vertices[k][1];

        // int256 fabsy1y2 = MathLib.abs(vertices[i][1] - vertices[j][1]);
        // int256 fabsy2y3 = MathLib.abs(vertices[j][1] - vertices[k][1]);
        // int256 m1;
        // int256 m2;
        // int256 mx1;
        // int256 mx2;
        // int256 my1;
        // int256 my2;
        int256 xc;
        int256 yc;
        int256 r;
        // int256 dx;
        // int256 dy;

        if (MathLib.abs(vertices[i][1] - vertices[j][1]) < EPSILON) {
            int256 m2;
            int256 mx2;
            int256 my2;
            m2 = -( int256(10**4) * (vertices[k][0] - vertices[j][0]) / (vertices[k][1] - vertices[j][1]));
            mx2 = int256(10**4) * (vertices[j][0] + vertices[k][0]) / 2;
            my2 = int256(10**4) * ( vertices[j][1] + vertices[k][1]) / 2;
            xc =  int256(10**4) * (vertices[j][0] + vertices[i][0]) / 2;
            yc = m2 * (xc - mx2)/(int256(10**4)) + my2;
        } else if (MathLib.abs(vertices[j][1] - vertices[k][1]) < EPSILON) {
            int256 m1;
            int256 mx1;
            int256 my1;
            m1 = -(int256(10**4) * ( vertices[j][0] - vertices[i][0]) / ( vertices[j][1] -  vertices[j][0]));
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
            // if(MathLib.abs(vertices[i][1] - vertices[j][1]) > MathLib.abs(vertices[j][1] - vertices[k][1])) {
            //     yc = m1 * (xc - mx1)/(int256(10**4)) + my1;
            // } else {
            //     yc = m2 * (xc - mx2) /(int256(10**4))+ my2;
            // }

            // yc = MathLib.abs(vertices[i][1] - vertices[j][1]) > MathLib.abs(vertices[j][1] - vertices[k][1]) ? m1 * (xc - mx1)/(int256(10**4)) + my1 : m2 * (xc - mx2) /(int256(10**4))+ my2;
        }

        // dx = vertices[j][0]*(int256(10**4)) - xc;
        // dy = vertices[j][1]*(int256(10**4)) - yc;
        
        r = ((vertices[j][0]*(int256(10**4)) - xc) * (vertices[j][0]*(int256(10**4)) - xc) + (vertices[j][1]*(int256(10**4)) - yc) * (vertices[j][1]*(int256(10**4)) - yc))/(int256(10**4));


        return([int256(i), int256(j), int256(k), int256(xc), int256(yc), r]);
    }

    function triangulate_1(int256[2][] memory _vertices) internal pure returns (uint256, int256[] memory) {

        uint256 n = _vertices.length;
        int256[2][] memory vertices = new int256[2][](n+3);
        uint256[] memory indices = new uint256[](n);
        int256[6][] memory open   = new int256[6][](500); 
        int256[6][] memory closed = new int256[6][](500);
        int256[] memory res = new int256[](500);
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

        // for (uint i = 0; i < _idx; i++) {
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
                        // splice j element from open array
                        // assembly { mstore(open, sub(mload(open), 1)) }
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
                    // splice j element from open array
                    // assembly { mstore(open, sub(mload(open), 1)) }
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
                            // assembly { mstore(edges, sub(mload(edges), 4)) }
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

    function drawTriangles(int256[2][] memory points, uint256 triangles_len, int256[] memory triangles, int256[3][3] memory colors) public pure returns (string memory) {

        string memory svgStr;
        uint256 color_idx = 0;

        for (uint i = 0; i < triangles_len; i += 3) {
            // int256 nonce = MathLib.random(3, msg.sender, triangles[i]);
            color_idx = (color_idx+1)%3;
            svgStr = string(
                abi.encodePacked(
                    svgStr,
                    '<polygon points="',
                    Strings.toString(points[uint256(triangles[i])][0]), ' ',
                    Strings.toString(points[uint256(triangles[i])][1]), ' ',
                    Strings.toString(points[uint256(triangles[i+1])][0]), ' ',
                    Strings.toString(points[uint256(triangles[i+1])][1]), ' ',
                    Strings.toString(points[uint256(triangles[i+2])][0]), ' ',
                    Strings.toString(points[uint256(triangles[i+2])][1]), '"',
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

}


contract TriangleDraw {

    int256[2][4] bodyPoints;

    constructor() {
        bodyPoints[0][0] = 200;
        bodyPoints[0][1] = 200;
        bodyPoints[1][0] = 210;
        bodyPoints[1][1] = 600;
        bodyPoints[2][0] = 610;
        bodyPoints[2][1] = 610;
        bodyPoints[3][0] = 600;
        bodyPoints[3][1] = 210;
    }


    function inside(int256 pt_x, int256 pt_y) public view returns(bool) {
        bool res = false;

        uint256 bp_len = bodyPoints.length;
        for (uint256 i = 0; i < bp_len; i++) {
            int256 xi = bodyPoints[i][0];
            int256 yi = bodyPoints[i][1];
            int256 xj = bodyPoints[(i+bp_len-1)%bp_len][0];
            int256 yj = bodyPoints[(i+bp_len-1)%bp_len][1];
            if ( ((yi > pt_y) != (yj > pt_y)) && (pt_x < ((xj - xi) * (pt_y - yi) / (yj - yi) + xi) ) ) {
                res = !res;
            }
        }

        return res;

    }


    function generatePoint(uint256 point_count) public view returns(int256[2][] memory) {
        int256[2][] memory res = new int256[2][](point_count+bodyPoints.length);
        int256 pt_x = 0;
        int256 pt_y = 0;
        int256 nonce = 731;
        uint256 i = 0;
        uint256 res_len = 0;

        // for(i=0; i<point_count; i++) {
        //         nonce = MathLib.random(uint256(500), msg.sender, nonce+int(i)*int(i));
        //         pt_x = nonce;
        //         nonce = MathLib.random(uint256(500), msg.sender, nonce+int(i)*int(i));
        //         pt_y = nonce;
    
        //         if(inside(pt_x, pt_y)) {
        //             res[i][0] = pt_x;
        //             res[i][1] = pt_y;
        //             res_len++;
        //         } 
        // }

        while( i < point_count) {
            nonce = MathLib.random(uint256(500), msg.sender, nonce+int(i)*int(i));
            pt_x = nonce;
            nonce = MathLib.random(uint256(500), msg.sender, nonce+int(i)*int(i));
            pt_y = nonce;
   
            if(inside(pt_x, pt_y)) {
                res[i][0] = pt_x;
                res[i][1] = pt_y;
                res_len++;
                i++;
            } 
        }

        for(i=0; i<bodyPoints.length; i++) {
            res[i+point_count][0] = bodyPoints[i][0];
            res[i+point_count][1] = bodyPoints[i][1];
            res_len++;
        }

        return res;

    }

    function drawTriangles(uint256 point_count, int256 R, int256 G, int256 B) public view returns(string memory) {

        int256[2][] memory vertices = new int256[2][](bodyPoints.length + point_count);
        int256[] memory triangles;
        int256[3][3] memory colors;
        uint256 triangles_len;
        string memory svgStr;
        uint256 color_idx = 0;
        // uint256 vertices_len;
        vertices = generatePoint(point_count);

        (triangles_len, triangles) = Delaunay.triangulate_1(vertices);
        colors = Delaunay.generateColorShades(R, G, B);

        for (uint i = 0; i < triangles_len; i += 3) {
            // int256 nonce = MathLib.random(3, msg.sender, triangles[i]);
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

        // return(triangles_len, triangles);

        // return Delaunay.drawTriangles(vertices, triangles_len, triangles, colors);

    }


}