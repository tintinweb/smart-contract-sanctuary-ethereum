// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.8.0 <0.9.0;

interface IConnector {
    function addPrincipal(address token, uint amount) external returns (uint);
    function withdrawPrincipal(address token, uint amount) external returns (uint);
    
    function checkInterest(address token, uint principal, uint cTokens) external returns (uint);
    function claimInterest(address token, uint principal, uint cTokens) external returns (uint, uint);

    function allowToken(address token, address cToken) external;
}

// SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interface/IConnector.sol";

/** 
 * @title 
 * @dev Implements
 */
contract NFTips is Ownable {
    string[] yieldProtocols;

    mapping (string => address[]) allowedTokens;

    mapping (string => address) connectors;
    //        yieldProtocol         

    mapping (address => mapping (string => bool)) isTokenAllowed;
    //        token           yield protocol   

    // tracks the amount of a set token principal is behind a certain receiver
    mapping (address => mapping (address => mapping (string => ReceiverPosition))) receiverPositions;
    //      receiver              token           yield protocol      amounts

    struct ReceiverPosition {
        uint principal;
        uint cTokens;
    }

    // tracks all the individual principals
    mapping (address => mapping (address => mapping (address => mapping (string => Principal)))) allPrincipals;
    //       sender             receiver              token          yieldProtocol                                          

    struct Principal {
        uint amount;
        uint senderPrincipalIndex;  // index of the corresponding principal in the senderPrincipals[sender] array
    }
    
    // tracks all the outgoing principals in the array
    mapping (address => SenderPrincipal[]) senderPrincipals; 
    //       sender  

    struct SenderPrincipal {
        address receiver;
        address token;
        uint amount; 
        string yieldProtocol;
    }

    event PrincipalAdded(address sender, address receiver, address token, string yieldProtocol, uint amount);
    event PrincipalWithdrawn(address sender, address receiver, address token, string yieldProtocol, uint amount);
    event PrincipalDeleted(address sender, address receiver, address token, string yieldProtocol);
    event CancelSupport(address sender, address receiver);
    event InterestClaimed(address receiver, address token, string yieldProtocol, uint amount);
    event NewYieldProtocol(string yieldProtocol);
    event NewTokenSupported(string yieldProtocol, address token, string tokenName); 

    constructor() {
    }

    modifier checkConnector(string memory _yieldProtocol) {
        require(
            connectors[_yieldProtocol] != address(0),
            "Yield protocol is not yet supported"
        );
        _;
    }

    modifier checkTokenAllowance(address _token, string memory _yieldProtocol) {
        require(
            isTokenAllowed[_token][_yieldProtocol],
            "Token is not yet supported on a yield protocol"
        );
        _;
    }

    /** 
    * @dev checks if token is allowed
    */
    function viewTokenAllowance(address _token, string memory _yieldProtocol) public view returns (bool) {
        return isTokenAllowed[_token][_yieldProtocol];
    }

    /** 
    * @dev returns a list of available yieldProtocols
    */
    function viewYieldProtocolsList() public view returns(string[] memory) {
        return yieldProtocols;
    }

    /** 
    * @dev returns connector address
    */
    function viewConnector(string memory _yieldProtocol) public view returns (address) {
        return connectors[_yieldProtocol];
    }

    /** 
    * @dev returns a list of allowed tokens
    */
    function viewAllowedTokens(string memory _yieldProtocol) public view returns(address[] memory) {
        return allowedTokens[_yieldProtocol];
    }

    /** 
    * @dev returns a particular principal
    */
    function viewPrincipal(
        address _sender,
        address _receiver,
        address _token, 
        string memory _yieldProtocol
    ) 
        public view checkConnector(_yieldProtocol) checkTokenAllowance(_token, _yieldProtocol) returns (uint, uint, uint)
    {
        Principal storage principal = allPrincipals[_sender][_receiver][_token][_yieldProtocol];
        ReceiverPosition storage receiverPosition = receiverPositions[_receiver][_token][_yieldProtocol];

        return (principal.amount, receiverPosition.principal, receiverPosition.cTokens);
    }

    /** 
    * @dev returns senderPrincipals[_sender][_index]
    */
    function viewSenderPrincipalByIndex(address _sender, uint _index) public view returns (uint, address, address, string memory) {
        SenderPrincipal storage senderPrincipal = senderPrincipals[_sender][_index];

        return (senderPrincipal.amount, senderPrincipal.token, senderPrincipal.receiver, senderPrincipal.yieldProtocol);
    }

    /** 
    * @dev iteration helper
    */
    function iterateSenderPrincipal(
        address _sender,
        address _receiver,
        address _token,
        string memory _yieldProtocol
    ) 
        private view returns (uint)
    {
        SenderPrincipal[] storage senderPrincipalsArray = senderPrincipals[_sender];

        uint total = 0;
        
        for (uint i = 0; i < senderPrincipalsArray.length; i++) {
            SenderPrincipal storage senderPrincipal = senderPrincipalsArray[i];

            if (_token != address(0) && senderPrincipal.token != _token) {
                continue;
            }

            if (_receiver != address(0) && senderPrincipal.receiver != _receiver) {
                continue;
            }
            
            if (
                bytes(_yieldProtocol).length != 0 && 
                connectors[senderPrincipal.yieldProtocol] != connectors[_yieldProtocol]
            ) {
                continue;
            }

            total += senderPrincipal.amount;
        }
        return total;
    }

    /** 
    * @dev checks the amount of certain principal
    */
    function viewSenderTokenPrinciple(
        address _sender,
        address _token
    ) 
        public view returns (uint) 
    {
        return iterateSenderPrincipal(_sender, address(0), _token, "");
    }

    /** 
    * @dev checks the amount of certain principal provided to a receiver
    */
    function viewSenderPrincipalToReceiver(
        address _sender,
        address _receiver,
        address _token
    ) 
        public view returns (uint)
    {
        return iterateSenderPrincipal(_sender, _receiver, _token, "");
    }

    /** 
    * @dev checks the amount of certain principal stored on a platform
    */
    function viewSenderPrincipalOnPlatform(
        address _sender,
        address _token, 
        string memory _yieldProtocol
    ) 
        public view checkTokenAllowance(_token, _yieldProtocol) returns (uint) 
    {
        return iterateSenderPrincipal(_sender, address(0), _token, _yieldProtocol);
    }

    /** 
    * @dev checks interest from a certain lending protocol and a certain token
    */
    function checkInterest(
        address _token,
        string memory _yieldProtocol
    ) 
        public checkConnector(_yieldProtocol) checkTokenAllowance(_token, _yieldProtocol) returns (uint) 
    {
        address connectorAddress = connectors[_yieldProtocol];
        ReceiverPosition storage receiverPosition = receiverPositions[msg.sender][_token][_yieldProtocol];

        uint principal = receiverPosition.principal;
        uint cTokens = receiverPosition.cTokens;

        return IConnector(connectorAddress).checkInterest(_token, principal, cTokens);
    }

    /** 
    * @dev claims interest from a certain lending protocol and a certain token
    */
    function claimInterest(
        address _token,
        string memory _yieldProtocol
    ) 
        public checkConnector(_yieldProtocol) checkTokenAllowance(_token, _yieldProtocol) 
    {
        address connectorAddress = connectors[_yieldProtocol];
        ReceiverPosition storage receiverPosition = receiverPositions[msg.sender][_token][_yieldProtocol];

        uint principal = receiverPosition.principal;
        uint cTokens = receiverPosition.cTokens;

        (uint interest, uint cTokenDiff) = IConnector(connectorAddress).claimInterest(_token, principal, cTokens);

        IERC20(_token).transferFrom(connectorAddress, msg.sender, interest);

        emit InterestClaimed(msg.sender, _token, _yieldProtocol, interest);

        receiverPosition.cTokens -= cTokenDiff;
    }

    /** 
    * @dev sets a new connector contract
    */
    function setConnector(
        string memory _yieldProtocol,
        address _connectorAddress
    ) 
        public onlyOwner() 
    {   
        connectors[_yieldProtocol] = _connectorAddress;
        yieldProtocols.push(_yieldProtocol);

        emit NewYieldProtocol(_yieldProtocol);
    }

    /** 
    * @dev allows token usage on platform
    */
    function allowToken(
        string memory _yieldProtocol,
        string memory _tokenName,
        address _token,
        address _cToken
    ) 
        public onlyOwner() checkConnector(_yieldProtocol) 
    {
        address connectorAddress = connectors[_yieldProtocol];

        allowedTokens[_yieldProtocol].push(_token);
        isTokenAllowed[_token][_yieldProtocol] = true;

        IConnector(connectorAddress).allowToken(_token, _cToken);

        emit NewTokenSupported(_yieldProtocol, _token, _tokenName);
    }
    
    /** 
    * @dev adds a principal to support a receiver
    */
    function addPrincipal(
        address _receiver,
        address _token, 
        string memory _yieldProtocol,
        uint _amount
    ) 
        public checkConnector(_yieldProtocol) checkTokenAllowance(_token, _yieldProtocol)
    {
        Principal storage principal = allPrincipals[msg.sender][_receiver][_token][_yieldProtocol];
        ReceiverPosition storage receiverPosition = receiverPositions[_receiver][_token][_yieldProtocol];
        SenderPrincipal[] storage senderPrincipalsArray = senderPrincipals[msg.sender];

        uint amountPrev = principal.amount;
        uint senderPrincipalIndex = principal.senderPrincipalIndex;
        
        if (senderPrincipalIndex == 0 && amountPrev == 0) {         // sets a new principal
            principal.senderPrincipalIndex = senderPrincipalsArray.length;

            SenderPrincipal memory senderPrincipal;

            senderPrincipal.receiver = _receiver;
            senderPrincipal.token = _token;
            senderPrincipal.amount = _amount;
            senderPrincipal.yieldProtocol = _yieldProtocol;

            senderPrincipalsArray.push(senderPrincipal);
        } else {                                                    // changes the existing principal
            senderPrincipalsArray[senderPrincipalIndex].amount += _amount;
        }

        principal.amount += _amount;
        receiverPosition.principal += _amount;      

        address connectorAddress = connectors[_yieldProtocol];

        IERC20(_token).transferFrom(msg.sender, connectorAddress, _amount);
        
        uint cTokenDiff = IConnector(connectorAddress).addPrincipal(_token, _amount);

        receiverPosition.cTokens += cTokenDiff;

        emit PrincipalAdded(msg.sender, _receiver, _token, _yieldProtocol, _amount);
    }
    
    /** 
    * @dev partially withdraw principal
    */
    function withdrawPrincipal(
        address _receiver,
        address _token, 
        string memory _yieldProtocol,
        uint _amount
    ) 
        public checkConnector(_yieldProtocol) checkTokenAllowance(_token, _yieldProtocol)
    {
        Principal storage principal = allPrincipals[msg.sender][_receiver][_token][_yieldProtocol];
        ReceiverPosition storage receiverPosition = receiverPositions[_receiver][_token][_yieldProtocol];

        require (
            principal.amount >= _amount,
            "Not enough principal"
        );

        principal.amount -= _amount;
        receiverPosition.principal -= _amount;

        uint senderPrincipalIndex = principal.senderPrincipalIndex;

        if (principal.amount == 0) {
            deletePrincipal(msg.sender, _receiver, _token, _yieldProtocol);
        } else {
            senderPrincipals[msg.sender][senderPrincipalIndex].amount -= _amount;
        }
        
        address connectorAddress = connectors[_yieldProtocol];
        uint cTokenDiff = IConnector(connectorAddress).withdrawPrincipal(_token, _amount);
        
        receiverPosition.cTokens -= cTokenDiff;

        IERC20(_token).transferFrom(connectorAddress, msg.sender, _amount);
        emit PrincipalWithdrawn(msg.sender, _receiver, _token, _yieldProtocol, _amount);
    }

    /** 
    * @dev fully withdraw all principals from a certain receiver
    */
    function cancelSupport(address _receiver) public {
        emit CancelSupport(msg.sender, _receiver);

        for (uint i = 0; i < senderPrincipals[msg.sender].length; i++) {
            SenderPrincipal storage senderPrincipal = senderPrincipals[msg.sender][i];

            address receiver = senderPrincipal.receiver;

            if (receiver == _receiver) {
                address token = senderPrincipal.token;
                uint amount = senderPrincipal.amount; 
                string memory yieldProtocol = senderPrincipal.yieldProtocol;

                Principal storage principal = allPrincipals[msg.sender][_receiver][token][yieldProtocol];
                ReceiverPosition storage receiverPosition = receiverPositions[_receiver][token][yieldProtocol];
                
                receiverPosition.principal -= amount;
                principal.amount = 0;

                deletePrincipal(msg.sender, _receiver, token, yieldProtocol);
                
                address connectorAddress = connectors[yieldProtocol];
                uint cTokenDiff = IConnector(connectorAddress).withdrawPrincipal(token, amount);
                
                receiverPosition.cTokens -= cTokenDiff;

                IERC20(token).transferFrom(connectorAddress, msg.sender, amount);
            }
        }
    }

    /** 
    * @dev fully withdraw a certain type of principal
    */
    function fullyWithdrawTokenPrincipal(address _token) public returns (uint) {
        SenderPrincipal[] storage senderPrincipalsArray = senderPrincipals[msg.sender];
        
        uint total = 0;

        for (uint i = senderPrincipalsArray.length - 1; true; i--) {
            SenderPrincipal storage senderPrincipal = senderPrincipalsArray[i];

            if (senderPrincipal.token == _token) {
                address receiver = senderPrincipal.receiver;
                uint amount = senderPrincipal.amount;
                
                address connectorAddress = connectors[senderPrincipal.yieldProtocol];
                
                Principal storage principal = allPrincipals[msg.sender][receiver][_token][senderPrincipal.yieldProtocol];
                ReceiverPosition storage receiverPosition = receiverPositions[receiver][_token][senderPrincipal.yieldProtocol];

                uint cTokenDiff = IConnector(connectorAddress).withdrawPrincipal(_token, amount);
                
                IERC20(_token).transferFrom(connectorAddress, msg.sender, amount);

                emit PrincipalWithdrawn(msg.sender, receiver, _token, senderPrincipal.yieldProtocol, amount);

                principal.amount = 0;
                receiverPosition.principal -= amount;
                receiverPosition.cTokens -= cTokenDiff;
                
                total += amount;

                deletePrincipal(msg.sender, receiver, _token, senderPrincipal.yieldProtocol);

                if (i == 0) {
                    break;
                }
            }
        }
                
        return total;
    }

    /** 
    * @dev deletes principal from the senderPrincipals[sender] array
    */
    function deletePrincipal(
        address _sender,
        address _receiver,
        address _token,
        string memory _yieldProtocol
    ) 
        private checkConnector(_yieldProtocol) checkTokenAllowance(_token, _yieldProtocol)
    {
        Principal storage principal = allPrincipals[_sender][_receiver][_token][_yieldProtocol];

        uint senderPrincipalIndex = principal.senderPrincipalIndex;

        SenderPrincipal[] storage senderPrincipalsArray = senderPrincipals[_sender];
        SenderPrincipal storage senderPrincipal = senderPrincipalsArray[senderPrincipalIndex];

        if (senderPrincipalIndex == senderPrincipalsArray.length - 1) {
            senderPrincipalsArray.pop();
        } else {
            SenderPrincipal storage lastElement = senderPrincipalsArray[senderPrincipalsArray.length - 1];
            
            senderPrincipal.receiver = lastElement.receiver; 
            senderPrincipal.token = lastElement.token;
            senderPrincipal.amount = lastElement.amount;
            senderPrincipal.yieldProtocol = lastElement.yieldProtocol;

            allPrincipals[_sender][lastElement.receiver][lastElement.token][lastElement.yieldProtocol].senderPrincipalIndex = senderPrincipalIndex;
            senderPrincipalsArray.pop();            
        }

        principal.senderPrincipalIndex = 0;

        emit PrincipalDeleted(_sender, _receiver, _token, _yieldProtocol);
    }
}