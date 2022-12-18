// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct AllowedContract {
    address addressed;
    string urlPath;
    string erc;
    bool isStaking;
    bool isProxy;
    bool exists;
}

struct AllowedPath {
    address[] addresses;
    address wallet;
    bool exists;
}

struct ContractableData { 
    mapping(address => AllowedContract[]) contractAllowlist;
    mapping(string => AllowedPath) paths;
    mapping(address => mapping(address => uint256)) contractIndexList;
    
    mapping(address => uint256) allowanceBalances;
}    

library SetContractable {

    error AlreadyAllowed(address requester, address contracted);  
    error PathAlreadyInUse(string path);   
    error PathDoesNotExist(string path);  
    error WTF(bool success,address wtf);
    error IsNotAllowed(address requester, address contracted); 
    
    function balanceOfAllowance(ContractableData storage self, address wallet) public view returns (uint256) {        
        return self.allowanceBalances[wallet];
    }     

    function allowances(ContractableData storage self, address wallet) public view returns (AllowedContract [] memory) {
        return self.contractAllowlist[wallet];
    }

    function addAllowance(ContractableData storage self, address allowed, string calldata urlPath, string calldata erc, bool isStaking, bool isProxy) public {
        self.contractIndexList[msg.sender][allowed] = balanceOfAllowance(self,msg.sender);
        self.contractAllowlist[msg.sender].push(AllowedContract(allowed,urlPath,erc,isStaking,isProxy,true));        
        self.allowanceBalances[msg.sender]++;
    }

    function allowContract(ContractableData storage self, address allowed, string calldata urlPath, string calldata erc, bool isStaking, bool isProxy) public {
        if (self.paths[urlPath].exists && self.paths[urlPath].wallet != msg.sender) {
            revert PathAlreadyInUse(urlPath);
        }   
        if (balanceOfAllowance(self,msg.sender) != 0) {
            uint256 index = self.contractIndexList[msg.sender][allowed];
            if (self.contractAllowlist[msg.sender][index].addressed == allowed) {
                revert AlreadyAllowed(msg.sender,allowed);
            }
        }
        addAllowance(self,allowed,urlPath,erc,isStaking,isProxy);

        address[] memory addressed = new address[](balanceOfAllowance(self, msg.sender));
        for (uint256 i = 0; i < balanceOfAllowance(self, msg.sender); i++) {
            addressed[i] = self.contractAllowlist[msg.sender][i].addressed;
        }
        self.paths[urlPath] = AllowedPath(addressed,msg.sender,balanceOfAllowance(self, msg.sender) > 0);
    } 

    function revokeContract(ContractableData storage self, address revoked) public {
        uint256 length = self.contractAllowlist[msg.sender].length;
        uint256 revokedIndex = self.contractIndexList[msg.sender][revoked];
        AllowedContract storage revokee = self.contractAllowlist[msg.sender][revokedIndex];
        // When the token to delete is the last token, the swap operation is unnecessary
        if (revokedIndex < length - 1) {
            AllowedContract memory lastItem = self.contractAllowlist[msg.sender][length - 1];
            self.contractAllowlist[msg.sender][revokedIndex] = lastItem; // Move the last token to the slot of the to-delete token
            self.contractIndexList[msg.sender][lastItem.addressed] = revokedIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete self.contractIndexList[msg.sender][revoked];
        self.contractAllowlist[msg.sender].pop();
        self.allowanceBalances[msg.sender]--;

        uint256 balanced = balanceOfAllowance(self, msg.sender);
        if (balanced > 0) {            
            address[] memory addressed = new address[](balanceOfAllowance(self, msg.sender));
            for (uint256 i = 0; i < balanceOfAllowance(self, msg.sender); i++) {
                addressed[i] = self.contractAllowlist[msg.sender][i].addressed;
            }
            self.paths[revokee.urlPath] = AllowedPath(addressed,msg.sender,true);
        } else {
            address[] memory addressed = new address[](0);
            self.paths[revokee.urlPath] = AllowedPath(addressed,msg.sender,false);      
        }

        
    }

    function pathAllows(ContractableData storage self, string calldata path) public view returns (AllowedPath memory) {
        if (!self.paths[path].exists) {
            revert PathDoesNotExist(path);
        }
        return self.paths[path];
    }
}