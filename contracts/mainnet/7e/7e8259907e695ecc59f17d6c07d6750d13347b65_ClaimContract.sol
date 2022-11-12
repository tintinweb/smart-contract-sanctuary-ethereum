/**
 *Submitted for verification at Etherscan.io on 2022-11-12
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
    uint8 private constant DECIMALS = 9;
    uint256 private constant DECIMALS_SCALING_FACTOR = 10**DECIMALS;
    uint256 private immutable INITIAL_TOKENS_CLAIMABLE;

    mapping(address => uint256) public claimAmounts;

    event InitializeEvent(address indexed tokenAddress);
    event ClaimEvent(address indexed claimee, uint256 indexed claimAmount);

    constructor() {

        address[16] memory addresses = [
            0x35129c4d51BA691C16ff6550fec2fF3072b9F9d2,
            0x135164C51e9F5C0a032631C942bb4B805511BD07,
            0xA5E1731517178CfAf396746cf055ff2229633632,
            0xF593d0044468f61706BB44004560b81Aef0d071D,
            0xbD9207c62E47d7D0f10aC99Ea5cd8182479e2abd,
            0xCB83f5B31f43827054022662A819688ae5c109E4,
            0xeFB8570E0C27D8c031D2c23dd4bD18a62402923f,
            0x3C87EDE6Be785830d25FF82999C6801B627b4D92,
            0x49b9189EE2001DFb2782B8F24b1e3418b66237F0,
            0x69d85E8f408F54C8EC16739B960Eca73cAB92EBD,
            0xB49617b323F42132afA3F211c99cEaAD6DFd46c7,
            0x438f4dac8E3153A8CA7bCe9a88c79af1c55ca36f,
            0xDB7F98c6F79c28D443a6A9F778750937Aa06D25A,
            0xc77dA006cF6da8cC5a876fCF56D84F6834D3c07d,
            0x7f9f61f5ccd313bA77959F394Fb4eF03A9B7Ca7F,
            0x7EF92380423d8dD884664325Ce206178b27989B3
        ];

        uint16[16] memory amounts = [            
            3500,
            3500,
            3500,  
            3500,
            3500,
            3500,  
            3500,
            3500,
            3500,  
            3500,
            3500,
            3500,  
            3500,
            3500,
            3500,  
            3500
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
        address claimee = msg.sender;

        uint256 amountToClaim = claimAmounts[claimee];
        require(amountToClaim > 0, "No tokens to claim");

        claimAmounts[claimee] = 0;
        token.transfer(claimee, amountToClaim);

        emit ClaimEvent(claimee, amountToClaim);
    }
}