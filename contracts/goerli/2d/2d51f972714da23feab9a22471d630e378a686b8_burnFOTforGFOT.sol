//SPDX-License-Identifier: MIT

pragma solidity =0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function owner() external view returns (address);

    function burn(uint256 _amount) external;
    function mint(address _to, uint256 _amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract burnFOTforGFOT {
    
    address public owner;
    IERC20 public FOT;
    IERC20 public gFOT;

    constructor(address _FOT, address _gFOT) {
        owner = msg.sender;
        FOT = IERC20(_FOT);
        gFOT = IERC20(_gFOT);
    }

    function mintGFOT(uint256 _amount) external {
        require(gFOT.owner() == address(this), "Mint: No mint permissions");
        require(FOT.balanceOf(msg.sender) >= _amount, "Mint: no FOT tokens to burn");
        
        FOT.burn(_amount);
        gFOT.mint(msg.sender, _amount);
    }
}