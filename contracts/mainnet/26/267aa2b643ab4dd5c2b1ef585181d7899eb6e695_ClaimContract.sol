/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

/**


*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender) , "!Owner"); _;
    }

    function isOwner(address account) private view returns (bool) {
        return account == owner;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }  
    event OwnershipTransferred(address owner);
}

contract ClaimContract is Ownable(msg.sender) {

    IERC20 public token;
    uint8 private constant DECIMALS = 8;
    uint256 private constant DECIMALS_SCALING_FACTOR = 10**DECIMALS;
    uint256 private immutable INITIAL_TOKENS_CLAIMABLE;

    mapping(address => uint256) public claimAmounts;

    event InitializeEvent(address indexed tokenAddress);
    event ClaimEvent(address indexed claimer, uint256 indexed claimAmount);

    constructor() {

        address[10] memory addresses = [
            0x716d73163475ba04e41C25211771AffFA5027928,
            0xB53c62856228CaEC06D1dbFac626DC4105846729,
            0xFCc17c6DA8E769C88DA4f94b4a1a1A83a2127287,
            0x135164C51e9F5C0a032631C942bb4B805511BD07,
            0xCB83f5B31f43827054022662A819688ae5c109E4,
            0xB2AE502eBB932f93738482F69b20cc020c0Ec9a9,
            0x69d85E8f408F54C8EC16739B960Eca73cAB92EBD,
            0xbD9207c62E47d7D0f10aC99Ea5cd8182479e2abd,
            0xB49617b323F42132afA3F211c99cEaAD6DFd46c7,
            0x35129c4d51BA691C16ff6550fec2fF3072b9F9d2
        ];

        uint24[10] memory amounts = [
            5000000,  
            5000000,  
            5000000,  
            5000000,  
            5000000,  
            5000000,  
            5000000,  
            5000000,  
            5000000,  
            5000000 
        ];
        assert(addresses.length == amounts.length);

        uint256 tokenSum;
        for(uint8 ix = 0;ix < amounts.length; ix++){
            tokenSum += amounts[ix];
            claimAmounts[addresses[ix]] = amounts[ix] * DECIMALS_SCALING_FACTOR;
        }

        INITIAL_TOKENS_CLAIMABLE = tokenSum * DECIMALS_SCALING_FACTOR;
    }

    function getInitialClaimableTokens() external view returns (uint256,uint256) {
        return (INITIAL_TOKENS_CLAIMABLE, INITIAL_TOKENS_CLAIMABLE / DECIMALS_SCALING_FACTOR);
    }

    function initialize(address tokenAddress) external onlyOwner {
        token = IERC20(tokenAddress);

        emit InitializeEvent(tokenAddress);
    }

    function claim() external {
        address claimer = msg.sender;

        uint256 amountToClaim = claimAmounts[claimer];
        require(amountToClaim > 0, "No tokens to claim");

        claimAmounts[claimer] = 0;
        token.transfer(claimer, amountToClaim);

        emit ClaimEvent(claimer, amountToClaim);
    }
}