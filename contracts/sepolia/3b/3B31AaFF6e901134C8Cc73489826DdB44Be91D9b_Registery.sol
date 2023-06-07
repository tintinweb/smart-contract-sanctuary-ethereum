// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ConstituencyFactory{
    address public constituency;
    uint public usedFunds;
    IERC20 erc20TokenAddress;
    string constituencyName;
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    modifier onlyOwner() {
        require(msg.sender == constituency, "You are not the constituency");
        _;
    }

    constructor(address _erc20TokenAddress, address _owner,string memory _constituencyName) {
        constituency = _owner;
        erc20TokenAddress = IERC20(_erc20TokenAddress);
        constituencyName = _constituencyName;
    }

    function setConstituencyAddress(address _constAddress) public onlyOwner {
        constituency = _constAddress;
    }

    function setERC20TokenAddress(address _erc20Token) public onlyOwner {
        erc20TokenAddress = IERC20(_erc20Token);
    }

    function transferTo(address _to, uint _amount) public onlyOwner {
        uint size;
        assembly {
            size := extcodesize(_to)
        }
        require(size > 0, "Can't transfer funds to citizens");
        usedFunds += _amount;
        erc20TokenAddress.transfer(_to, _amount);
        emit Transfer(msg.sender,_to,_amount);
    }
}

contract Registery{
    address[] public constituencies;
    address public owner;
    address public erc20Token;
    mapping (address => address) userConstituencies;
    mapping (address => bool) isValidConstiuencies;
    
    constructor(address _erc20Token){
        owner = msg.sender;
        erc20Token = _erc20Token;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "You don't have authority");
        _;
    }
    function setNewOwner(address _user) onlyOwner public {
        owner = _user;
    }
    function addNewConstituency(string memory _name) onlyOwner public {
        ConstituencyFactory constituency = new ConstituencyFactory(erc20Token,msg.sender,_name);
        constituencies.push(address(constituency));
        userConstituencies[msg.sender] = address(constituency);
        isValidConstiuencies[address(constituency)] = true;
    }
    function getConstituency(address _user) public view returns (address) {
        return userConstituencies[_user];
    }
    function isValidConstiuency(address _contituency) public view returns (bool) {
        return isValidConstiuencies[_contituency];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}