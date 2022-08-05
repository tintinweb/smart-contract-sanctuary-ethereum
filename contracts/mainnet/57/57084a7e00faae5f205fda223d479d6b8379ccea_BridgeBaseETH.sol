/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

contract BridgeBaseETH is Ownable{
    
    struct InterOp {
        string _uuid;
        address _source;
        address _sourceTokenAddress;
        uint _sourceAmount;
        string _sourceNetwork;
        address _destination;
        uint _destinationAmount;
        address _destinationTokenAddress;
        string _destinationNetwork;
    }

    mapping(string => InterOp) public txDetails;

    mapping(string => bool) public txInitStatus;
    mapping(string => bool) public txClaimStatus;

    string public network;
    
    mapping(address => bool) public authorizationStatus;
    mapping(string => bool) public authorizedDestinationNetwork;
    mapping(address => bool) public authorizedToken;

    /* Events */
    event DepositInitiated(
                        string _uuid,
                        address _source,
                        address _sourceTokenAddress,
                        string _sourceNetwork,
                        uint _sourceAmount,
                        address _destination,
                        uint _destinationAmount,
                        address _destinationTokenAddress,
                        string _destinationNetwork
                    );

    event DepositClaimed( 
                        string _uuid,
                        address _source,
                        address _sourceTokenAddress,
                        uint _sourceAmount,
                        string _sourceNetwork,
                        address _destination,
                        uint _destinationAmount,
                        address _destinationTokenAddress,
                        string _destinationNetwork
                    );


    event UpdateAuthorization(address _auth,bool _status);
    event UpdateAuthorizedDestinationNetwork(string _network,bool _status);
    event UpdateAuthorizedToken(address _token,bool _status);
    event WithdrawnAllLiquidityForToken(address _receiver,uint _amount,address _token);
    event WithdrawnCollectedFees(address _receiver,uint _amount);

    constructor(string memory _network) {
        network = _network;

        // Update Authorized Caller
        updateAuthorization(0xa021c67fd2514a5031d00f8659ae0fA3E89D566f,true);

        // Update Destination Network
        updateAuthorizationForNetwork("ETH",true);
        updateAuthorizationForNetwork("MATIC",true);
        updateAuthorizationForNetwork("BSC",true);
        updateAuthorizationForNetwork("AVAX",true);

        // Update Token
        updateAuthorizationForToken(0xdAC17F958D2ee523a2206206994597C13D831ec7,true); //USDT 
        updateAuthorizationForToken(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,true); //USDC
        updateAuthorizationForToken(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,true); //WETH
        updateAuthorizationForToken(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,true); //WBTC

    }    

    modifier onlyAuth {
        require(_msgSender() == owner() || authorizationStatus[_msgSender()] == true, "Not an authorized address");
        _;
    }

    function compareStrings(string memory a, string memory b) public view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function deposit(string memory _uuid,
                    address _sourceTokenAddress,
                    uint _sourceAmount,
                    address _destination,
                    uint _destinationAmount,
                    address _destinationTokenAddress,
                    string memory _destinationNetwork) public payable returns (bool) {
        
        // Check if Source and Network is not same
        require(compareStrings(network,_destinationNetwork) == false, "Cannot be same networks");

        // Check if UUID is not already processed
        require(txInitStatus[_uuid] == false, "Request with this uuid is already processed");
        
        // Check if Amount is more than zero
        require(_sourceAmount > 0 , "Amount cannot be zero");

        // Desitnation Network validation
        require(authorizedDestinationNetwork[_destinationNetwork] == true, "Not allowed as destination network");

        // Check if the sourceAmount is allowed to be transferred to contract address
        require(IERC20(_sourceTokenAddress).allowance(_msgSender(),address(this)) >= _sourceAmount, "Requested Amount is less than what is approved by sender");
        
        // Transfer Desired Amount with IERC20 to contracts address
        require(IERC20(_sourceTokenAddress).transferFrom(_msgSender(),address(this),_sourceAmount), "Requested Amount not transferred");


        txDetails[_uuid] =  InterOp({
            _uuid: _uuid,
            _source: _msgSender(),
            _sourceNetwork: network,
            _sourceTokenAddress: _sourceTokenAddress,
            _sourceAmount: _sourceAmount,
            _destination: _destination,
            _destinationNetwork: _destinationNetwork,
            _destinationAmount: _destinationAmount,
            _destinationTokenAddress: _destinationTokenAddress
        });


        txInitStatus[_uuid] = true;

        emit DepositInitiated(
                         _uuid,
                         _msgSender(),
                        _sourceTokenAddress,
                        network,
                        _sourceAmount,
                        _destination,
                        _destinationAmount,
                        _destinationTokenAddress,
                        _destinationNetwork
                    );
        
        return true;
    }


    function claim( string memory _uuid,
                    address _source,
                    address _sourceTokenAddress,
                    uint _sourceAmount,
                    string memory _sourceNetwork,
                    address _destination,
                    uint _destinationAmount,
                    address _destinationTokenAddress) public onlyAuth returns(bool){

        // Check if UUID is not already processed
        require(txClaimStatus[_uuid] == false,"Request with this uuid is already processed");
        
        // Check if enough liquidity exists
        require(IERC20(_destinationTokenAddress).balanceOf(address(this)) >= _destinationAmount, "Not Sufficient Liquidity for given token");
        
         txDetails[_uuid] =  InterOp({
            _uuid: _uuid,
            _source: _source,
            _sourceNetwork: _sourceNetwork,
            _sourceTokenAddress: _sourceTokenAddress,
            _sourceAmount: _sourceAmount,
            _destination: _destination,
            _destinationNetwork: network,
            _destinationAmount: _destinationAmount,
            _destinationTokenAddress: _destinationTokenAddress
        });

        // Update Status
        txClaimStatus[_uuid] = true;

        // Transfer Tokens
        IERC20(_destinationTokenAddress).transfer(_destination,_destinationAmount);

        return true;

    }

    function updateAuthorization(address _auth,bool _status) public onlyOwner {

        authorizationStatus[_auth] = _status;
        emit UpdateAuthorization(_auth,_status);
    }

    function updateAuthorizationForNetwork(string memory _destinationNetwork,bool _status) public onlyOwner {

        authorizedDestinationNetwork[_destinationNetwork] = _status;
        emit UpdateAuthorizedDestinationNetwork(_destinationNetwork,_status);
    }

    function updateAuthorizationForToken(address _token,bool _status) public onlyOwner {

        authorizedToken[_token] = _status;
        emit UpdateAuthorizedToken(_token,_status);
    }

    function withdrawAllLiquidityForToken(address _token) public onlyOwner returns(bool){
        uint _availableTokens = IERC20(_token).balanceOf(address(this));
        require(_availableTokens >= 0, "Not Sufficient Liquidity for given token");

        IERC20(_token).transfer(msg.sender,_availableTokens);

        emit WithdrawnAllLiquidityForToken(msg.sender,_availableTokens,_token);
        return true;
    }

    function withdrawCollectedFees() public onlyOwner returns(bool){
        address payable _receiver = payable(address(this));
        uint _amount = _receiver.balance;

        _receiver.transfer(_amount);

        emit WithdrawnCollectedFees(msg.sender,_amount);
        return true;

    }



    
    
}