/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

struct TokenData {
    uint tokenId;
    uint level;
    uint xCoordinate;
    uint yCoordinate;
    int elevation;
    int structureSpaceX;
    int structureSpaceY;
    int structureSpaceZ;
    string zoneName;
    string[10] zoneColors;
    string[9] characterSet;
}

enum Status {
    Terrain, 
    Daydream, 
    Terraformed, 
    OriginDaydream, 
    OriginTerraformed
}

interface ITerraformsData {
  function tokenSupplementalData(uint tokenId) 
    external 
    view
    returns (TokenData memory); 

  function tokenToStatus(uint tokenId) 
    external 
    view
    returns (Status); 

  function tokenToAuthorizedDreamer(uint tokenId) 
    external 
    view
    returns (address); 

  function ownerOf(uint256 tokenId) 
    external 
    view
    returns (address);

  function commitDreamToCanvas(uint tokenId, uint[16] memory dream) external; 

  function enterDream(uint tokenId) external;

  function getApproved(uint256 tokenId) 
    external 
    view 
    returns (address);

  function transferFrom(address from, address to, uint256 tokenId) external;
}

/// @title Terraforms Zone Dreamer
/// @author yeetljuice
/// @notice Extends the terraform authorized dreamer functionality to allow any 
///         terraform holder with a tokenId of the same zone to commit a dream
///         to the tokenIds owned by this contract or that has this contract as 
///         the given authorizedDreamer.
contract TerraformsZoneDreamer {

    event Terraformed(uint tokenId, address terraformer);
    event TerraformAvailableForDreaming(uint tokenId, address owner, string zoneName);
    event TerraformNoLongerAvailableForDreaming(uint tokenId, address owner, string zoneName);

    ITerraformsData terraformsContract = ITerraformsData(0x4E1f41613c9084FdB9E34E11fAE9412427480e56);

    mapping(uint => address) public tokenIdOwner;

    /// @notice Checks the dreamer (msg.sender) owns tokenIdDreamer and tokenIdDreamer has
    ///         the same zoneName as the tokenIdToDream zoneName
    /// @param tokenIdToDream The tokenId to dream
    /// @param tokenIdDreamer The tokenId owned by the dreamer (msg.sender) 
    ///        that is of the same zone as the tokenIdToDream
    modifier validZoneDreamer(uint tokenIdToDream, uint tokenIdDreamer) {
        require(terraformsContract.ownerOf(tokenIdDreamer) == msg.sender, 
                "The dreamer (msg.sender) doesn't own tokenIdDreamer");
        require(keccak256(bytes(getTokenIdZoneName(tokenIdToDream))) == 
                keccak256(bytes(getTokenIdZoneName(tokenIdDreamer))),
                "The tokenIdDreamer and tokenIdToDream don't have the same zoneName");
        _;
    }

    /// @notice Transfer ownership of a terraform tokenId to this contract. This allows
    ///         the token to continually re-dreamt and drawn on by owners of the same zone terraform.
    ///         Ownership can be transferred back to the tokenId owner 
    /// @param tokenId the terraform tokenId to give the contract ownership of  
    function transferOwnershipToContract (uint tokenId) public {
        require(terraformsContract.getApproved(tokenId) == address(this), "Approval for token needs to be set to this smart contract address");
        terraformsContract.transferFrom(msg.sender, address(this), tokenId);
        tokenIdOwner[tokenId] = msg.sender;
        emit TerraformAvailableForDreaming(tokenId, msg.sender, getTokenIdZoneName(tokenId));
    }

    /// @notice Remove tokenId from contract making it no longer dreamable and transfer back 
    ///         to owner who submitted it to the contract
    /// @param tokenId the terraform tokenId to remove from the contract
    function transferOwnershipFromContract (uint tokenId) public {
        require(tokenIdOwner[tokenId] == msg.sender, 'Not owner of tokenId when submitted to contract');
        terraformsContract.transferFrom(address(this), msg.sender, tokenId);
        tokenIdOwner[tokenId] = address(0);
        emit TerraformNoLongerAvailableForDreaming(tokenId, msg.sender, getTokenIdZoneName(tokenId));
    }
    
    /// @notice Sets a dreaming token's canvas to a user-supplied drawing if the 
    ///         dreamer (msg.sender) owns tokenIdDreamer and tokenIdDreamer has
    ///         the same zoneName as the tokenIdToDream zoneName
    /// @dev The drawing data is encoded as 16 uints. The 64 least significant
    ///      digits of each uint represent values from 0-9 at successive x,y
    ///      positions on the token, beginning in the top left corner. Each 
    ///      value will be obtained from left to right by taking the current 
    ///      uint mod 10, and then advancing to the next digit until all uints 
    ///      are exhausted. 
    /// @param tokenIdToDream The tokenId to dream
    /// @param dream An array of 16 uints, each representing the heightmap 
    ///              indices of two rows
    /// @param tokenIdDreamer The tokenId owned by the dreamer (msg.sender) 
    ///        that is of the same zone as the tokenIdToDream
    function commitDreamToCanvas(uint tokenIdToDream, uint[16] memory dream, uint tokenIdDreamer) public validZoneDreamer(tokenIdToDream, tokenIdDreamer) {
        terraformsContract.commitDreamToCanvas(tokenIdToDream, dream);
        emit Terraformed(tokenIdToDream, msg.sender);
    }

    /// @notice Puts the tokenIdToDream in a dreamed start so a new dream can be committed to canvas.
    ///         Only tokenIds that are owned by this contract (using transferOwnershipToContract) can be
    ///         reverted to the dream state using this contract.
    /// @param tokenIdToDream The tokenId to put in a dreamed state
    /// @param tokenIdDreamer The tokenId owned by the dreamer (msg.sender) 
    ///        that is of the same zone as the tokenIdToDream
    function enterDream(uint tokenIdToDream, uint tokenIdDreamer) public validZoneDreamer(tokenIdToDream, tokenIdDreamer) {
        require(tokenIdOwner[tokenIdToDream] != address(0), "Token not owned by contract. Only the token owner can set to dream state.");
        terraformsContract.enterDream(tokenIdToDream);
    }

    /// @notice Helper function to get the zoneName of a tokenId 
    /// @param tokenId The terraform tokenId to get the zoneName of
    function getTokenIdZoneName(uint tokenId) public view returns (string memory) {
        return terraformsContract.tokenSupplementalData(tokenId).zoneName;
    }

    /// @notice Check if the terraform is ready to be dreamed using commitDreamToCanvas
    /// @param tokenId the terraform tokenId to check 
    function readyToCommitDream(uint tokenId) public view returns (bool) {
        address tokenOwner = terraformsContract.ownerOf(tokenId);
        address authDreamer = terraformsContract.tokenToAuthorizedDreamer(tokenId);
        Status status = terraformsContract.tokenToStatus(tokenId);

        bool canDreamToken = tokenOwner == address(this) || authDreamer == address(this);

        require(canDreamToken, "Token hasn't been given permission to be dreamt through this contract");
        if (tokenOwner == address(this)) {
            require(status == Status(1), "Token not in dream state. Can be put into dream state using enterDream");
        } else {
            require(status == Status(1), "Token not in dream state. Must be put in dream state by token owner");
        }
        return true;
    }
}