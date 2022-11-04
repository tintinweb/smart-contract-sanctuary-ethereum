//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);

    function transfer(address _to, uint256 _amount) external returns (bool);
    
}

contract Swap{
    IERC20 token;

    struct OrderDetails{
        address tokenFrom;//token address you wish to swap from
        address tokenTo;//token address you wish to swap to
        uint amountIn;
        uint amountOut;
        address userAddr; // address to transfer token to
        bool status;
    }

    uint ID = 1; 

    mapping(uint => OrderDetails) _details;

    /// @dev function to create order
    function createOrder(address _tokenFrom, address _tokenTo, uint _amountIn, uint _amountOut) external {
        require(IERC20(_tokenFrom).transferFrom(msg.sender, address(this), _amountIn), "failed");
        OrderDetails storage od = _details[ID];
        od.tokenFrom = _tokenFrom;
        od.tokenTo = _tokenTo;
        od.amountIn = _amountIn;
        od.amountOut = _amountOut;
        od.userAddr = msg.sender;
        od.status = true;

        ID++;
    }

    /// @dev function to execute order

    function executeOrder(uint _userID) external{
        OrderDetails storage od = _details[_userID];
        require(od.status == true);
        uint amount = od.amountOut;
        require(IERC20(od.tokenTo).balanceOf(msg.sender) > amount, "balance not sufficient");
        require(IERC20(od.tokenTo).transferFrom(msg.sender, address(this), amount), "transaction failed");
        IERC20(od.tokenFrom).transfer(msg.sender, od.amountIn);
        //IERC20(address(this)).transfer(msg.sender, od.amountIn);
        IERC20(od.tokenTo).transfer(od.userAddr, amount);

        //emit IERC20.Transfer( od.tokenTo, od.userAddr, amount);
    }

}