/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Realesae {

    address public manager;         // manager
    IERC20 public token;            // token contract
    
    uint256 total;                  // total release amount
    uint[] times;                   // release time
    uint[] radios;                  // release radio
    uint[] amounts;                 // release amounts
    uint256 wTime = 0;              // withdraw times
    
    /*
     * constructor
     */
    constructor(IERC20 _token, uint256 _total) {

        token = IERC20(_token);
        total = _total * 10**token.decimals();

        times = [1684339200, 1684339200, 1747497600, 1779033600, 1810569600, 1842192000];
        radios = [5, 15, 20, 20, 20, 20];
        for ( uint i = 0; i < radios.length; i++ ) {
            amounts.push(total * radios[i] / 100);
        }
        
        manager = msg.sender;
    }

    /*
     * release times
     */
    function releaseTimes() public view returns(uint[] memory) {
        return times;
    }

    /*
     * release radios
     */
    function releaseRadios() public view returns(uint[] memory) {
        return radios;
    }

    /*
     * release amounts
     */
    function releaseAmounts() public view returns(uint[] memory) {
        return amounts;
    }

    /**
     * withdraw
     */
    function withdraw(address _receiver) public onlyManager {

        uint _now = block.timestamp;
        require(_now >= times[0], "it is not time to release !");
        require(token.balanceOf(address(this)) > 0, "the balanceOf contract is zero !");
        
        uint256 _total;
        for ( uint i = 0; i < amounts.length; i++ ) {
            _total = _total + amounts[i];
        }
        require(_total > 0, "the amount has been released in full!");

        uint256 released = 0; 
        if (times[0] < _now && _now < times[1]) {
            released = amounts[0];
            amounts[0] = 0;
        } else if (times[1] < _now && _now < times[2]) {
            released = amounts[0] + amounts[1];
            amounts[0] = 0;
            amounts[1] = 0;
        } else if (times[2] < _now && _now < times[3]) {
            released = amounts[0] + amounts[1] + amounts[2];
            amounts[0] = 0;
            amounts[1] = 0;
            amounts[2] = 0;
        } else if (times[3] < _now && _now < times[4]) {
            released = amounts[0] + amounts[1] + amounts[2] + amounts[3];
            amounts[0] = 0;
            amounts[1] = 0;
            amounts[2] = 0;
            amounts[3] = 0;
        } else if (times[4] < _now && _now < times[5]) {
            released = amounts[0] + amounts[1] + amounts[2] + amounts[3] + amounts[4];
            amounts[0] = 0;
            amounts[1] = 0;
            amounts[2] = 0;
            amounts[3] = 0;
            amounts[4] = 0;
        } else if (_now > times[5] ) {
            released = amounts[0] + amounts[1] + amounts[2] + amounts[3] + amounts[4] + amounts[5];
            amounts[0] = 0;
            amounts[1] = 0;
            amounts[2] = 0;
            amounts[3] = 0;
            amounts[4] = 0;
            amounts[5] = 0;
        }
        require(released > 0, "no amount need released !");
        require(released <= token.balanceOf(address(this)), "the balanceOf contract is not enough !");

        token.transfer(_receiver, released);
    }

    /*
     * set manager
     */
    function setManager(address _manager) public onlyManager returns(address) {
        manager = _manager;
        return manager;
    }

    /*
     * only manager
     */
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

}