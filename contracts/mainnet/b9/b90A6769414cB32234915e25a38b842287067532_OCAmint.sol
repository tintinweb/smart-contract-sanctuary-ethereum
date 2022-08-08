/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

pragma solidity =0.7.6;

// Developed by Orcania (https://orcania.io/)
interface IERC20{
         
    function transfer(address recipient, uint256 amount) external;
    
}

abstract contract OMS { //Orcania Management Standard

    address private _owner;

    event OwnershipTransfer(address indexed newOwner);

    receive() external payable {}

    constructor() {
        _owner = msg.sender;
    }

    //Modifiers ==========================================================================================================================================
    modifier Owner() {
        require(msg.sender == _owner, "OMS: NOT_OWNER");
        _;  
    }


    //Read functions =====================================================================================================================================
    function owner() public view returns (address) {
        return _owner;
    }
    
    //Write functions ====================================================================================================================================
    function setNewOwner(address user) external Owner {
        _owner = user;
        emit OwnershipTransfer(user);
    }
    
    function withdraw(address payable to, uint256 value) external Owner {
        sendValue(to, value);  
    }

    function withdrawERC20(address token, address to, uint256 value) external Owner {
        IERC20(token).transfer(to, value);   
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "INSUFFICIENT_BALANCE");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "UNABLE_TO_SEND_VALUE RECIPIENT_MAY_HAVE_REVERTED");
    }

}

contract OCAmint is OMS {
    IERC20 immutable OCA = IERC20(0x3f8C3b9F543910F611585E3821B00af0617580A7);

    uint256 private _price;

    //Read functions=========================================================================================================================
    function price() external view returns (uint256) {return _price;}

    //Owner Write Functions========================================================================================================================
    function changePrice(uint256 price) external Owner {_price = price;}  

    //User write functions=========================================================================================================================
    function mint() external payable {
        uint256 price = _price;

        require(msg.value % price == 0);
        uint256 amount = msg.value / price * 10**18;

        OCA.transfer(msg.sender, amount);
    }

}