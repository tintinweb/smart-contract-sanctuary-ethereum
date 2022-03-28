// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
import "./UnidoDistribution.sol";

contract UnidoBurner is UnidoDistribution {
    
    using SafeMath for uint256;
    
    // Storing the instance of UDO Token in udo variable.
    UnidoDistribution udo = UnidoDistribution(0xea3983Fc6D0fbbC41fb6F6091f68F3e08894dC06);
    
    // Events triggered during the execution of respective code blocks
    event Stage1(bool applicable);
    event Stage2(bool applicable);
    event TokensBurnt(uint256 numberOfBurntTokens);
    
    mapping (address => bool) private moderator;
    
    // Declaring the limit at which Stage 2 is triggered.
    uint256 constant limit = 92000000 * 10**decimals;
    
    constructor() {
        // Owner of the contract is by default a moderator.
        // Owner of CFBF must be the owner of UDO ERC-20 Contract.
        moderator[msg.sender] = true;
    }
    
    modifier onlyModerator {
        require(moderator[msg.sender] == true, 'Only the moderators allowed by the owner of the contract can do that');
        _;
    }

    // Can be called only by the owner of the contract. Give access to certain people to call distribute() function.
    function addModerator(address _mod) public onlyOwner {
        moderator[_mod] = true;
    }

    // Can be called only by the moderators.
    // Distribute any number of tokens from the contract address.
    function distribute(uint256 tokens) public onlyModerator {

        require(tokens > 0, "Cannot distribute 0 Tokens!");
        require(tokens <= 1000000 * 10**decimals, "Cannot distribute more than 1 million UDO Tokens at once!");
        
        // Fetching the total supply.
        uint256 supply = udo.totalSupply();
        
        // Target distribution addresses
        address EDF = 0x2F9BF79fbd31345B33A76E3D630C173823af27cB;
        address reserve = 0x5c80F9982DcCc3F2C8b4CbDFdf60E684798e4284;
        
        uint256 actualAllocationStage_1 = 0;
        uint256 actualAllocationStage_2 = 0;
        
        // Maximum Tokens that can follow Stage 1 are
        // (supply - limit) / 0.6
        uint256 maxAllocationStage_1 = supply.sub(limit).div(6).mul(10);
        
        if(tokens > maxAllocationStage_1) {
            actualAllocationStage_2 = tokens.sub(maxAllocationStage_1);
        } else {
            actualAllocationStage_2 = 0;
        }
        
        actualAllocationStage_1 = tokens.sub(actualAllocationStage_2);
        // actualAllocationStage_1 = actualAllocationStage_1.div(10);

        uint256 tokensToBurn = 0;
        uint256 tokensToEDFandReserve = 0;

        // Stage 1 : Burnt at 60/20/20 down to limit
        if(actualAllocationStage_1 > 0) {
            // Follow Stage 1:
            // Burn: 60%,
            // Reserve: 20%,
            // EDF: 20%.
            
            tokensToEDFandReserve = actualAllocationStage_1.mul(2).div(10);
            tokensToBurn = actualAllocationStage_1.sub(tokensToEDFandReserve.mul(2));
            
            udo.burn(tokensToBurn);
            TokensBurnt(tokensToBurn);
            udo.transfer(reserve, tokensToEDFandReserve);
            udo.transfer(EDF, tokensToEDFandReserve);
            Stage1(true);
        }
        
        // Stage 2
        if(actualAllocationStage_2 > 0) {
            // Follow Stage 2:
            // Reserve: 50%,
            // EDF: 50%.
            actualAllocationStage_2 = actualAllocationStage_2.div(2);
            
            udo.transfer(reserve, actualAllocationStage_2);
            udo.transfer(EDF, actualAllocationStage_2);
            Stage2(true);
        }

    }
    
}