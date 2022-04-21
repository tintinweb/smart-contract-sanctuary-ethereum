/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

uint256 constant dim1 = 36;
uint256 constant dim2 = 36;
uint256 constant dim  = dim1 * dim2;

contract Canvas {
    struct Cell {
        address user;       // 20 B
        bytes3  color;      // 3 B
        // uint72  _draw_time;  // 9 B
        uint256  draw_time;
    }
    
    Cell [dim] private canvas;

    event Draw(address indexed painter, uint32 index, bytes3 color);

    function draw(uint32 index, bytes3 color) external {
        Cell memory cell = Cell(msg.sender, color,block.timestamp);
        canvas[index] = cell;
        emit Draw(msg.sender, index, color);
    }
    
    // getCanvas(0, 2): 70,960 gas
    function getCanvas(uint8 start, uint8 end) public view returns (Cell [] memory) {
        // The following two expressions also imply (start>=0) and (start<=end)
        require(start < dim1);
        require(end   <= dim1);
        uint8 size = end - start; // The size of slicing the first dimension
        
        if(size == 0) {
            return new Cell[](0);
        }
        else {
            Cell[] memory output = new Cell[](dim2 * size);
            
            for(uint8 i; i < size; i++)
                for(uint8 j; j < dim2; j++)
                    output[(dim2 * i) + j] = canvas[dim2 * (start + i) + j];
            
            return output;
        }
    }
    //  function isPaintable(uint32 index) public view returns(bool) {
    //     if (block.timestamp - canvas[index].draw_time > 5 minutes) {
    //         return true;
    //     } else {
    //         return false;
    //     }
    // }
}