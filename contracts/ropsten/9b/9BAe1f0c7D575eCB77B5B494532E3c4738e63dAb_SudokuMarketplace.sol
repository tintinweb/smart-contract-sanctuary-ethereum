// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
/**
* @title Sudoku Marketplace
* @author Nassim Dehouche
*/

import "./Ownable.sol";
import "./Pausable.sol";


contract SudokuMarketplace is Ownable, Pausable{ 

/// @dev Toggle pause boolean 
    function togglePause() external onlyOwner {
        if (paused()) {_unpause();}
        else _pause();
    }


/// @dev Sudoku creation event   
event sudokuCreated(address _proposer, uint _index);
/// @dev Solution submission event 
event solutionSubmitted(address _solver, address _proposer, uint _index);
/// @dev Sudoku solution event 
event sudokuSolved(address _solver, address _proposer, uint _index, uint _value); 


/// @notice Time-window to submit a solution from the time a Sudoku grid is created
uint public deadline=600; 
/// @notice Fee to be paid by solvers
uint public fee=1000000000; 

/* @notice Test Sudoku: 
* [[5,3,4,6,7,8,9,1,2],
* [6,7,2,1,9,5,3,4,8],
* [1,9,8,3,4,2,5,6,7],
* [8,5,9,7,6,1,4,2,3],
* [4,2,6,8,5,3,7,9,1],
* [7,1,3,9,2,4,8,5,6],
* [9,6,1,5,3,7,2,8,4],
* [2,8,7,4,1,9,6,3,5],
* [3,4,5,2,8,6,1,7,9]];
 */

/// @dev The Sudoku structure
struct Sudoku{ 
  uint[9][9] grid;
  uint creationTime;
  bool solved;
  address payable solver;
  uint value;
  }

/// @dev Mapping proposers with an array of their proposed Sudokus
mapping(address => Sudoku[]) public sudokus; 

/// @dev Receive function
receive() external payable { 
}

/// @dev Fallback function. We check data length in fallback functions as a best practice
fallback() external payable {
require(msg.data.length == 0); 
}


/// @dev Digit verification for proposers
function validDigitsProblem(uint[9][9] calldata _grid) public pure returns (bool valid)
{   
    for(uint i = 0; i < 9; i++)
    {   
        for(uint j = 0; j < 9; j++)
        {
            if (_grid[i][j] > 9)
            {
                return false;
            }
        }
    }
    return true;
}

/// @dev Digit verification for solvers
function validDigitsSolution(uint[9][9] calldata _grid) public pure returns (bool valid)
{   
    for(uint i = 0; i < 9; i++)
    {   
        for(uint j = 0; j < 9; j++)
        {
            if (_grid[i][j]==0 || _grid[i][j] > 9)
            {
                return false;
            }
        }
    }
    return true;
}
  
 
/// @dev Sudoku verification for both proposers and solvers
function validSudoku(uint[9][9] calldata _grid) public pure returns (bool valid)
{ 
    bool[10] memory unique;
 
    //Check uniqueness in rows
    for(uint i = 0; i < 9; i++)
    {   for (uint j=1;j<10;j++){
        unique[j]=false;   
         }
        for(uint j = 0; j < 9; j++)
        {
            uint current = _grid[i][j];
            if (current!=0 && unique[current])
            {
                return false;
            }
            unique[current] = true;
        }
    }
   
    //Check uniqueness in columns
    for(uint i = 0; i < 9; i++)
    {
        for (uint j=1;j<10;j++){
        unique[j]=false;   
         }
        for(uint j = 0; j < 9; j++)
        {
 
            uint current = _grid[j][i];
            if (current!=0 && unique[current])
            {
                return false;
            }
            unique[current] = true;
        }
    }

    //Check uniqueness in sub-grids
    for(uint i = 0; i < 7; i += 3)
    {
        for(uint j = 0; j < 7; j += 3)
        {
            for (uint k=1;k<10;k++){
            unique[k]=false;   
            }
            // Traverse current block
            for(uint k = 0; k < 3; k++)
            {
                for(uint l = 0; l < 3; l++)
                {         
                    // Stores current row number
                    uint X = i + k;
 
                    // Stores current column number
                    uint Y = j + l;
 
                    // Stores current value
                    uint current = _grid[X][Y];
 
                    // Check if current is duplicated
                    if (current!=0 && unique[current])
                    {
                        return false;
                    }
                    unique[current] = true;
                }
            }
        }
    }
 
    // If all conditions are atisfied
    return true;
}

/// @dev Modifier for proposers
modifier OnlyIfValidProblem(uint[9][9] calldata _grid) {
    require(validDigitsProblem(_grid));
    require(validSudoku(_grid));
    _;
}


/// @notice Submit function for proposers
function submitProblem(uint[9][9] calldata _grid) public payable 
OnlyIfPaidEnough() 
OnlyIfValidProblem(_grid)
whenNotPaused
returns (uint _id)
{   


_id= sudokus[msg.sender].length;
sudokus[msg.sender].push(Sudoku({
grid: _grid, 
creationTime:block.timestamp,
solved: false, 
solver: payable(address(0)),
value:msg.value
}));
emit sudokuCreated(msg.sender, _id);
return _id;
}



/// @dev Checks that solution if for the right problem
function rightPuzzle(uint[9][9] memory _problem, uint[9][9] calldata _solution) public pure returns (bool valid)
{   
    for(uint i = 0; i < 9; i++)
    {   
        for(uint j = 0; j < 9; j++)
        {
            if (_problem[i][j] !=0 && _solution[i][j]!=_problem[i][j])
            {
                return false;
            }
        }
    }
    return true;
}


/// @dev Checks deadline
modifier OnlyIfStillOpen(address proposer, uint index) {
    require(sudokus[proposer][index].solved==false &&block.timestamp<=sudokus[proposer][index].creationTime+deadline);
    _;
}

/// @dev Checks that sudoku hasn't been already solved
modifier OnlyIfNotSolved(address proposer, uint index) {
    require(sudokus[proposer][index].solved==false &&block.timestamp>sudokus[proposer][index].creationTime+deadline);
    _;
}

/// @dev Payment modifier
modifier OnlyIfPaidEnough() {
    require(msg.value==fee);
    _;
}

/// @dev Digit modifier for solutions
modifier OnlyIfValidDigitsSolution(uint[9][9] calldata _grid) {
    require(validDigitsSolution(_grid));
    _;
}

/**
@dev The submitSolution function. We want to allow wrong submissions to collect fees,
we just verify that they are not trivially wrong with modifier OnlyIfValidDigitsSolution()
*/
function submitSolution(address proposer, uint index, uint[9][9] calldata _solution) public payable
OnlyIfStillOpen(proposer,index)
OnlyIfPaidEnough()
OnlyIfValidDigitsSolution(_solution)
{  
emit solutionSubmitted(msg.sender, proposer, index);
sudokus[proposer][index].value+=msg.value;
if(rightPuzzle(sudokus[proposer][index].grid,_solution) && validSudoku(_solution)){
sudokus[proposer][index].solved=true;
sudokus[proposer][index].solver=payable(msg.sender);
emit sudokuSolved(msg.sender, proposer, index, sudokus[proposer][index].value);
uint _value=sudokus[proposer][index].value; 
sudokus[proposer][index].value=0;
 
(bool sent, ) = msg.sender.call{value: _value}("");
        require(sent, "Failed to send Ether");
 }
 
}


//@notice Proposers can withdraw the value held in their Sudoku if no one could solve it
function withdrawValue(uint index) public 
OnlyIfNotSolved(msg.sender,index)
whenNotPaused
{   
uint _value=sudokus[msg.sender][index].value; 
sudokus[msg.sender][index].value=0;
sudokus[msg.sender][index].solved=true;
sudokus[msg.sender][index].solver=payable(msg.sender);
emit sudokuSolved(msg.sender, msg.sender, index, _value);
(bool sent, ) = msg.sender.call{value: _value}("");
        require(sent, "Failed to send Ether");
}
}