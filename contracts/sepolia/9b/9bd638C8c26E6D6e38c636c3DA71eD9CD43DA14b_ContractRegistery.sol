// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ContractFactory.sol";
import "./Registery.sol";

contract ContractRegistery is Registery{
    
    constructor(address _erc20Token, address _registery) Registery(_erc20Token,msg.sender,_registery){}
    function addNewContract(string memory _name,string memory _description) onlyOwner public {
        ContractFactory contractFactory = new ContractFactory(msg.sender,address(erc20Token),_name,_description,address(registery));
        super.addNewRegistery(address(contractFactory));
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Factory.sol";
import "./IRegistery.sol";

contract ContractFactory is Factory {
    string public name;
    string public contractDescription;

    constructor(address _owner,address _erc20,string memory _name,string memory _description,address _registery) Factory(msg.sender,_erc20,_registery) {
        name = _name;
        owner = _owner;
        contractDescription = _description;
        registery = IRegistery(_registery);
        // contractRegistery = IContractRegistery(_registery);
    }

    function transferTo(address _to, uint _amount) public onlyOwner {
        require(registery.isValidRegistry(_to),"Not a valid Contractor");
        super.transfer(_to,_amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IRegistery.sol";

contract Factory {
    address public owner;
    IERC20 erc20TokenAddress;
    uint public usedFunds;
    IRegistery public registery;
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address _owner,address _erc20,address _registery) {
        owner = _owner;
        erc20TokenAddress = IERC20(_erc20);
        registery = IRegistery(_registery);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the constituency");
        _;
    }

    function transfer(address _to, uint _amount) public onlyOwner {
        uint size;
        assembly {
            size := extcodesize(_to)
        }
        require(size > 0, "Can't transfer funds to citizens");
        usedFunds += _amount;
        erc20TokenAddress.transfer(_to, _amount);
        emit Transfer(msg.sender, _to, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRegistery {
    function isValidRegistry(address _registery) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IRegistery.sol";

contract Registery{
    address[] public registeriesAddress;
    address public owner;
    IERC20 public erc20Token;
    IRegistery public registery;
    mapping (address => address) userRegistery;
    mapping (address => bool) isValidRegistries;
    
    constructor(address _erc20Token,address _owner,address _registery){
        owner = _owner;
        erc20Token = IERC20(_erc20Token);
        registery = IRegistery(_registery);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You don't have authority");
        _;
    }
    
    function setRegistery(address _registery) public onlyOwner{
        registery = IRegistery(_registery);
    }
    function setNewOwner(address _user) onlyOwner public {
        owner = _user;
    }

    function addNewRegistery(address _registery) onlyOwner public {
        // ConstituencyFactory constituency = new ConstituencyFactory(erc20Token,msg.sender,_name);
        registeriesAddress.push(_registery);
        userRegistery[msg.sender] = _registery;
        isValidRegistries[_registery] = true;
    }
    function getAllRegisteries() public view returns (address[] memory) {
        return registeriesAddress;
    }
    function getRegistery(address _user) public view returns (address) {
        return userRegistery[_user];
    }
    function isValidRegistry(address _registery) public view returns (bool) {
        return isValidRegistries[_registery];
    }
}