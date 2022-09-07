/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IToken {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract BridgeBase {
    IToken public token;
    address private _owner;
    address payable public feeReceiver;
    uint256 public swapFee;
    bytes32 public chain;
    bytes32 constant ETH = 0x4554480000000000000000000000000000000000000000000000000000000000;
    bytes32 constant BSC = 0x4253430000000000000000000000000000000000000000000000000000000000;

    mapping(address => mapping(uint32 => uint256)) public swapper;
    mapping(address => uint32) public swapperNonce;
    mapping(address => mapping(uint32 => uint256)) public receiver;
    mapping(address => uint32) public receiverNonce;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FeeReceiverChanged(address indexed previousFeeReceiver, address indexed newFeeReceiver);
    event SwapFeeChanged(uint256 swapFee, uint256 newSwapFee);
    event ChainChanged(bytes32 chain, bytes32 newChain);
    event TokenWithdrawn(uint256 amount, address to);
    


    // enum Chain { ETH, BSC }
    event Swapped(
        address indexed from,
        uint256 amount,
        uint date,
        uint32 nonce,
        bytes32 fromChain,
        bytes32 toChain,
        uint256 payedFee
    );
    event Bridged(
        address indexed to,
        uint256 amount,
        uint date,
        uint32 nonce,
        bytes32 fromChain,
        bytes32 toChain
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address _token, bytes32 _chain, uint256 _fee, address _feeReceiver) {
        require(_chain == ETH || _chain == BSC, 'Wrong chain');
        _owner = msg.sender;
        feeReceiver = payable(_feeReceiver);
        swapFee = _fee;
        chain = _chain;
        emit OwnershipTransferred(address(0), _feeReceiver);
        token = IToken(_token);
    }


    /**
     * @dev prepare to swap ERC20 to opposite chain
     */
    function swap (uint256 amount, uint32 nonce) public payable {
        require(msg.value == swapFee, 'Wrong fee for swap process');
        require(amount > 0, 'Amount must be greater than zero');
        require(amount <= token.balanceOf(msg.sender), "Not enough tokens in your own");
        require(nonce == swapperNonce[msg.sender]+1, "Invalid nonce");
        require(swapper[msg.sender][nonce] <= 0, "Already swapped");

        require(token.allowance(msg.sender, address(this)) >= amount, "Make sure that the allowance is not lower than token amount you are going to transfer");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed: not enought funds.");

        emit Swapped(msg.sender, amount, block.timestamp, nonce, chain == ETH ? ETH : BSC, chain == ETH ? BSC : ETH, msg.value);

        swapperNonce[msg.sender] = nonce;
        swapper[msg.sender][nonce] = amount;
        // pay the service fee for swap
        payable(feeReceiver).transfer(msg.value);
    }

    /**
     * @dev transfer ERC20
     */
    function bridge (uint256 amount, address to, uint32 nonce) public virtual onlyOwner {
        require(amount > 0, 'Amount must be greater than zero');
        require(receiver[to][nonce] <= 0, "Already bridged");
        require(amount <= token.balanceOf(address(this)), "Not enough tokens in the reserve");
        emit Bridged(to, amount, block.timestamp, nonce, chain == ETH ? BSC : ETH, chain == ETH ? ETH : BSC);
        receiverNonce[to] = nonce;
        receiver[to][nonce] = amount;
        token.transfer(to, amount);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Secure function for withdraw token.
     * Can only be called by the current owner.
     */
    function withdrawToken(uint256 amount) public virtual onlyOwner {
        require(
            amount > 0,
            "Amount must be greater than zero"
        );
        emit TokenWithdrawn(amount, _owner);
        token.transfer(_owner, amount);

    }

    /**
     * @dev Change feeReceiver to a new account (`newFeeReceiver`).
     * Can only be called by the current owner.
     */
    function changeFeeReceiver(address newFeeReceiver) public virtual onlyOwner {
        require(
            newFeeReceiver != address(0),
            "New fee receiver is the zero address"
        );
        emit FeeReceiverChanged(feeReceiver, newFeeReceiver);
        feeReceiver = payable(newFeeReceiver);
    }

    /**
     * @dev Change swapFee amount (newFee).
     * Can only be called by the current owner.
     */
    function changeSwapFee(uint256 newFee) public virtual onlyOwner {
        require( newFee != swapFee, "New fee must be different fron existing");
        require( newFee >= 0, "Fee must be greater or equal to zero");
        emit SwapFeeChanged(swapFee, newFee);
        swapFee = newFee;
    }

    /**
     * @dev Change chain string (newChain).
     * Can only be called by the current owner.
     */
    function changeChain(bytes32 newChain) public virtual onlyOwner {
        require(newChain == ETH || newChain == BSC, 'Wrong chain');
        require(
            newChain != chain,
            "New chain must be different fron existing"
        );
        emit ChainChanged(chain, newChain);
        chain = newChain;
    }

    /**
     * @dev Secure function for withdraw native token.
     * Can only be called by the current owner.
     */
    function withdraw() public virtual onlyOwner {
        payable(feeReceiver).transfer(address(this).balance);
    }

    
}

contract SkiBridge is BridgeBase {
    constructor(address token, bytes32 chain, uint256 fee, address feeReceiver) BridgeBase(token, chain, fee, feeReceiver) {}
}