/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

/**
 * GasCheck
 * Auther: @enoch_eth
*/
pragma solidity ^0.8.0;

 /**
 * @title Contract that will work with ERC223 tokens.
 */
 
 interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract IERC223Recipient {

 struct ERC223TransferInfo
    {
        address token_contract;
        address sender;
        uint256 value;
        bytes   data;
    }
    
    ERC223TransferInfo private tkn;
    uint256 loopnum;
    
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenFallback(address _from, uint _value, bytes memory _data) public virtual
    {
        /**
         * @dev Note that inside of the token transaction handler the actual sender of token transfer is accessible via the tkn.sender variable
         * (analogue of msg.sender for Ether transfers)
         * 
         * tkn.value - is the amount of transferred tokens
         * tkn.data  - is the "metadata" of token transfer
         * tkn.token_contract is most likely equal to msg.sender because the token contract typically invokes this function
        */
        tkn.token_contract = msg.sender;
        tkn.sender         = _from;
        tkn.value          = _value;
        tkn.data           = _data;
        
        for (uint i = 3; i <= loopnum; i++) {
            require(i-1 > 1);
        }
        // ACTUAL CODE
    }
}

contract MyContract is IERC223Recipient {

    address payable public owner;
    IERC20 public ATOKEN;

    constructor() payable {
        owner = payable(msg.sender);
    }

    function withdraw() public {
        uint amount = address(this).balance;
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function withdrawERC20(address erc20token, uint amount) public {
        require(msg.sender == owner);
        address _ATOKEN = erc20token;
        ATOKEN = IERC20(_ATOKEN);
        _safeTransfer(ATOKEN, msg.sender, amount);
    }

    function setnum(uint256 num) public {
        loopnum = num;
    }

    receive() external payable {
        for (uint i = 3; i <= loopnum; i++) {
            require(i-1 > 1);
        }
    }

    function _safeTransfer(
        IERC20 token,
        address recipient,
        uint amount
    ) private {
        bool sent = token.transfer(recipient, amount);
        require(sent, "Token transfer failed");
    }


}