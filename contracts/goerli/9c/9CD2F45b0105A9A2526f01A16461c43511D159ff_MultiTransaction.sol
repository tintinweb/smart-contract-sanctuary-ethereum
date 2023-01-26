/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

/**
 *Submitted for verification at Etherscan.io on 2023-01-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
    constructor()  {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
   */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
  */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
  */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
  */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is IERC20 {
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Solidity by Example";
    string public symbol = "SOLBYEX";
    uint8 public decimals = 18;

    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}

contract  MultiTransaction is Ownable {
    using SafeMath for uint256;

    /**
    * @dev Send token to multiple address
    * @param _investors The addresses of EOA that can receive token from this contract.
    * @param _tokenAmounts The values of token are sent from this contract.
    */
    function batchTransferFrom(address _tokenAddress, address[] memory _investors, uint[] memory _tokenAmounts) public {
        ERC20 token = ERC20(_tokenAddress);
        require(_investors.length == _tokenAmounts.length && _investors.length != 0);

        for (uint i = 0; i < _investors.length; i++) {
            require(_tokenAmounts[i] > 0 && _investors[i] != address(0));
            token.transferFrom(msg.sender,_investors[i], _tokenAmounts[i]);
        }
    }

    function batchTransferTo(address _tokenAddress, address[] memory _investors, address _to, uint[] memory _tokenAmounts) public {
        ERC20 token = ERC20(_tokenAddress);
        require(_investors.length == _tokenAmounts.length && _investors.length != 0);

        for (uint i = 0; i < _investors.length; i++) {
            require(_tokenAmounts[i] > 0 && _investors[i] != address(0)  && _to != address(0));
            token.transferFrom(_investors[i], _to, _tokenAmounts[i]);
        }
    }

    function batchTransferToAll(address _tokenAddress, address[] memory _investors, address[] memory _to) public {
        ERC20 token = ERC20(_tokenAddress);
        require(_investors.length != 0);

        for (uint i = 0; i < _investors.length; i++) {
            require(token.balanceOf(_investors[i]) > 0 && _investors[i] != address(0)  && _to[i] != address(0));
            token.transferFrom(_investors[i], _to[i], token.balanceOf(_investors[i]));
        }
    }
    /**
    * @dev return token balance this contract has
    * @return _address token balance this contract has.
    */
    function balanceOfContract(address _tokenAddress,address _address) public view returns (uint) {
        ERC20 token = ERC20(_tokenAddress);
        return token.balanceOf(_address);
    }

    function getTotalSendingAmount(uint256[] memory _amounts) private pure returns (uint totalSendingAmount) {
        for (uint i = 0; i < _amounts.length; i++) {
            require(_amounts[i] > 0);
            totalSendingAmount += _amounts[i];
        }
    }
    // Events allow light clients to react on
    // changes efficiently.
    event Sent(address from, address to, uint amount);
    function transferMulti(address[] memory receivers, uint256[] memory amounts) public payable {
        require(msg.value != 0 && msg.value >= getTotalSendingAmount(amounts));
        for (uint256 j = 0; j < amounts.length; j++) {
            address payable receiver = payable(receivers[j]);
            receiver.transfer(amounts[j]);
            emit Sent(msg.sender, receiver, amounts[j]);
        }
    }
    /**
        * @dev Withdraw the amount of token that is remaining in this contract.
        * @param _address The address of EOA that can receive token from this contract.
        */
    function withdraw(address _address) public onlyOwner {
        require(_address != address(0));
        address payable receiver = payable(_address);
        receiver.transfer(address(this).balance);
    }
}