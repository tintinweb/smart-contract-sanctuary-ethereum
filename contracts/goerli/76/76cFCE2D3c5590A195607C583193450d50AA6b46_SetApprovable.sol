// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct ApprovableData { 

    mapping(address => uint256) contractApprovals;
    mapping(address => address[]) approvedForAll;
    mapping(address => mapping(address => uint256)) approvedForAllIndex;

    mapping(uint256 => uint256) tokenApprovals;
    mapping(uint256 => TokenApproval[]) approvedForToken;
    mapping(uint256 => mapping(address => uint256)) approvedForTokenIndex;

    mapping(uint256 => TokenApproval) tokens;

    bool exists;
}    

struct TokenApproval {
    address approval;
    bool exists;
}

error AlreadyApproved(address operator, uint256 tokenId);
error AlreadyApprovedContract(address operator);
error AlreadyRevoked(address operator, uint256 tokenId);
error AlreadyRevokedContract(address operator);
error TokenNonExistent(uint256 tokenId);


library SetApprovable {     

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);    

    function isApprovedForAll(ApprovableData storage self, address owner, address operator) public view returns (bool) {        
        return self.approvedForAll[owner].length > self.approvedForAllIndex[owner][operator] ? 
            (self.approvedForAll[owner][self.approvedForAllIndex[owner][operator]] != address(0)) :
            false;
    }   

    function revokeApprovals(ApprovableData storage self, address owner, uint256[] memory ownedTokens) public {            
        
        for (uint256 i = 0; i < ownedTokens.length; i++) {
            revokeTokenApproval(self,ownedTokens[i]);
        }
        
        address[] memory contractApprovals = self.approvedForAll[owner];
        for (uint256 i = 0; i < contractApprovals.length; i++) {
            address approved = contractApprovals[i];    
            revokeApprovalForContract(self, approved, owner);             
        }
    }   

    function revokeTokenApproval(ApprovableData storage self, uint256 token) public {            
        TokenApproval[] memory approvals = self.approvedForToken[token];
        for (uint256 j = 0; j < approvals.length; j++) {
            revokeApprovalForToken(self, approvals[j].approval, token);
        }         
    }       

    function getApproved(ApprovableData storage self, uint256 tokenId) public view returns (address) {
        return self.approvedForToken[tokenId].length > 0 ? self.approvedForToken[tokenId][0].approval : address(0);
    }     

    function approveForToken(ApprovableData storage self, address operator, uint256 tokenId) public {
        uint256 index = self.approvedForTokenIndex[tokenId][operator];
        if (index < self.approvedForToken[tokenId].length) {
            if (self.approvedForToken[tokenId][index].exists) {
                revert AlreadyApproved(operator, tokenId);
            }            
        }
   
        self.approvedForToken[tokenId].push(TokenApproval(operator,true));
        self.approvedForTokenIndex[tokenId][operator] = self.approvedForToken[tokenId].length-1;
        self.tokenApprovals[tokenId]++;
        
        emit Approval(msg.sender, operator, tokenId); 
    } 

    function revokeApprovalForToken(ApprovableData storage self, address revoked, uint256 tokenId) public {
        uint256 index = self.approvedForTokenIndex[tokenId][revoked];
        if (!self.approvedForToken[tokenId][index].exists) {
            revert AlreadyRevoked(revoked,tokenId);
        }
        
        // When the token to delete is not the last token, the swap operation is unnecessary
        if (index != self.approvedForToken[tokenId].length - 1) {
            TokenApproval storage tmp = self.approvedForToken[tokenId][self.approvedForToken[tokenId].length - 1];
            self.approvedForToken[tokenId][self.approvedForToken[tokenId].length - 1] = self.approvedForToken[tokenId][index];
            self.approvedForToken[tokenId][index] = tmp;
            self.approvedForTokenIndex[tokenId][tmp.approval] = index;            
        }

        // This also deletes the contents at the last position of the array
        delete self.approvedForTokenIndex[tokenId][revoked];
        self.approvedForToken[tokenId].pop();

        self.tokenApprovals[tokenId]--;
    }

    function approveForContract(ApprovableData storage self, address operator) public {
        uint256 index = self.approvedForAllIndex[msg.sender][operator];
        if (self.approvedForAll[msg.sender].length > index) {
            if (self.approvedForAll[msg.sender][index] != address(0)) {
                revert AlreadyApprovedContract(self.approvedForAll[msg.sender][index]);
            }
        }
   
        self.approvedForAll[msg.sender].push(operator);
        self.approvedForAllIndex[msg.sender][operator] = self.approvedForAll[msg.sender].length-1;
        self.contractApprovals[msg.sender]++;

        emit ApprovalForAll(msg.sender, operator, true); 
    } 

    function revokeApprovalForContract(ApprovableData storage self, address revoked, address owner) public {
        uint256 index = self.approvedForAllIndex[owner][revoked];
        address revokee = self.approvedForAll[owner][index];
        if (revokee != revoked) {
            revert AlreadyRevokedContract(revoked);
        }
        
        // When the token to delete is not the last token, the swap operation is unnecessary
        if (index != self.approvedForAll[owner].length - 1) {
            address tmp = self.approvedForAll[owner][self.approvedForAll[owner].length - 1];
            self.approvedForAll[owner][self.approvedForAll[owner].length - 1] = self.approvedForAll[owner][index];
            self.approvedForAll[owner][index] = tmp;
            self.approvedForAllIndex[owner][tmp] = index;            
        }
        // This also deletes the contents at the last position of the array
        delete self.approvedForAllIndex[owner][revoked];
        self.approvedForAll[owner].pop();

        self.contractApprovals[owner]--;

        emit ApprovalForAll(owner, revoked, false); 
    }    

}