/**
 *Submitted for verification at Etherscan.io on 2022-11-25
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

        address[13] memory addresses = [
            0x0DDE5C11105eE1d07A80e26657FEA89186DA6dA5, 
            0xB53c62856228CaEC06D1dbFac626DC4105846729,
            0xFCc17c6DA8E769C88DA4f94b4a1a1A83a2127287, 
            0x716d73163475ba04e41C25211771AffFA5027928,
            0x49b9189EE2001DFb2782B8F24b1e3418b66237F0,
            0x35129c4d51BA691C16ff6550fec2fF3072b9F9d2,
            0xc77dA006cF6da8cC5a876fCF56D84F6834D3c07d,
            0x7EF92380423d8dD884664325Ce206178b27989B3, 
            0x135164C51e9F5C0a032631C942bb4B805511BD07, 
            0xbD9207c62E47d7D0f10aC99Ea5cd8182479e2abd, 
            0x179429485fcED63867699dBc322fbb76d13c3B68,
            0x91b7079004BCC9c864565408E25E8FEB48046Cb3,
            0x494119A7d69050eA6cE575528E4a89453856542a
        ];

        uint8[13] memory amounts = [
            35,  
            35,  
            35,  
            35,  
            35,  
            35,  
            35,  
            35,  
            35,  
            35,  
            35,  
            60,
            55
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