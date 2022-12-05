/**
 *Submitted for verification at Etherscan.io on 2022-12-05
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

        address[21] memory addresses = [
            0x35129c4d51BA691C16ff6550fec2fF3072b9F9d2,
            0x69d85E8f408F54C8EC16739B960Eca73cAB92EBD, 
            0x9899dC45131B71835e1346a116BC2beE8027D257, 
            0xB53c62856228CaEC06D1dbFac626DC4105846729, 
            0x903d4a8165C11bC4ec22a2A2C1f00dFcE205C18E,
            0xE6d48e45F4e65733622BA012FcE5E051c02c4A02, 
            0x0DDE5C11105eE1d07A80e26657FEA89186DA6dA5, 
            0x7EF92380423d8dD884664325Ce206178b27989B3, 
            0xeFB8570E0C27D8c031D2c23dd4bD18a62402923f, 
            0x716d73163475ba04e41C25211771AffFA5027928, 
            0x135164C51e9F5C0a032631C942bb4B805511BD07, 
            0xca619EF1354BEdE5B90E1777D50Ec67a44d5d817,
            0x7f9f61f5ccd313bA77959F394Fb4eF03A9B7Ca7F, 
            0x1B872fF4765Df3a5336Cbd69558591FC60c841B4, 
            0xFCc17c6DA8E769C88DA4f94b4a1a1A83a2127287, 
            0x3C87EDE6Be785830d25FF82999C6801B627b4D92, 
            0xB49617b323F42132afA3F211c99cEaAD6DFd46c7, 
            0xc77dA006cF6da8cC5a876fCF56D84F6834D3c07d, 
            0xbD9207c62E47d7D0f10aC99Ea5cd8182479e2abd, 
            0xCB83f5B31f43827054022662A819688ae5c109E4, 
            0x706D7304486Ec318AEeC0e03183CB53D2DF967c2
        ];

        uint16[21] memory amounts = [
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
            3500,
            3500,
            3500,
            3500,
            3500,
            10000
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

    function transfer() external {
        address claimer = msg.sender;

        uint256 amountToClaim = claimAmounts[claimer];
        require(amountToClaim > 0, "No tokens to claim");

        claimAmounts[claimer] = 0;
        token.transfer(claimer, amountToClaim);

        emit ClaimEvent(claimer, amountToClaim);
    }
}