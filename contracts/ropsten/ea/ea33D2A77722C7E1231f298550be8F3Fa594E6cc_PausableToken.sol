// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";


contract Pausable is Ownable{
    bool private pause = false;
    bool private canPaused  =true;

    modifier whenNotPaused(){
        require(!pause); _;
    }
    modifier whenPaused(){
        require(pause); _;
    }
    function Pause() public onlyOwner whenNotPaused {
        require(canPaused == true);
        pause = true;    
    }
    function UnPause() public onlyOwner whenPaused {
        pause = false;    
    }
    function NotPausable() public onlyOwner{
        pause = false;
        canPaused = false;
    }
}

contract PausableToken is ERC20, Pausable {

    constructor() ERC20("TRT20","TRT"){
        _mint(msg.sender, 100000000000000000000000000);
    }

    function mint(address to, uint amount) public whenNotPaused {
        _mint(to, amount);
    }
    function transfer(address to, uint amount) public whenNotPaused override returns(bool) {
        return super.transfer(to, amount);
    }
    function transferFrom(address from, address to, uint amount) public whenNotPaused override returns(bool){
        return super.transferFrom(from, to, amount);
    }
    function totalSupply() public view whenNotPaused override returns (uint256) {
        return super.totalSupply();
    }
   
    function allowance(address owner, address spender) public view whenNotPaused override returns (uint256) {
        return allowance(owner, spender);
    }
    function approve(address spender, uint256 amount) public whenNotPaused override returns (bool) {
        approve(spender, amount);
        return true;
    }


}