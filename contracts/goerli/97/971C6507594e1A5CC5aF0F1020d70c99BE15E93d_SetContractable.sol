// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct AllowedContract {
    address addressed;
    string urlPath;
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
    error IsNotAllowed(address requester, address contracted); 
    
    function balanceOfAllowance(ContractableData storage self, address wallet) public view returns (uint256) {        
        return self.allowanceBalances[wallet];
    }     

    function allowances(ContractableData storage self, address wallet) public view returns (AllowedContract [] memory) {
        return self.contractAllowlist[wallet];
    }

    function allowContract(ContractableData storage self, address allowed, string calldata urlPath) public {
        uint256 index = self.contractIndexList[msg.sender][allowed];
        if (index > 0 && self.contractAllowlist[msg.sender][index].exists) {
            revert AlreadyAllowed(msg.sender,allowed);
        }
        if (self.paths[urlPath].exists && self.paths[urlPath].wallet != msg.sender) {
            revert PathAlreadyInUse(urlPath);
        }        

        if (balanceOfAllowance(self, msg.sender) >= self.contractAllowlist[msg.sender].length) {            
            self.contractAllowlist[msg.sender].push(AllowedContract(allowed,urlPath,true));
        } else {
            self.contractAllowlist[msg.sender][balanceOfAllowance(self, msg.sender)] = AllowedContract(allowed,urlPath,true);
            self.contractIndexList[msg.sender][allowed] = balanceOfAllowance(self, msg.sender);            
        }
        address[] memory addressed = new address[](self.contractAllowlist[msg.sender].length);
        for (uint256 i = 0; i < self.contractAllowlist[msg.sender].length; i++) {
            addressed[i] = self.contractAllowlist[msg.sender][i].addressed;
        }
        self.paths[urlPath] = AllowedPath(addressed,msg.sender,true);
        self.allowanceBalances[msg.sender]++;  
    } 

    function pathAllows(ContractableData storage self, string calldata path) public view returns (AllowedPath memory) {
        if (!self.paths[path].exists) {
            revert PathDoesNotExist(path);
        }
        return self.paths[path];
    }

    function revokeContract(ContractableData storage self, address revoked) public {
        uint256 index = self.contractIndexList[msg.sender][revoked];
        AllowedContract storage revokee = self.contractAllowlist[msg.sender][index];
        if (revokee.addressed != revoked) {
            revert IsNotAllowed(msg.sender,revoked);
        }
        // When the token to delete is the last token, the swap operation is unnecessary
        if (self.contractIndexList[msg.sender][revoked] != balanceOfAllowance(self, msg.sender) - 1) {
            self.contractAllowlist[msg.sender][self.contractIndexList[msg.sender][revoked]] = self.contractAllowlist[msg.sender][balanceOfAllowance(self,msg.sender) - 1]; // Move the last token to the slot of the to-delete token
            self.contractIndexList[msg.sender][self.contractAllowlist[msg.sender][balanceOfAllowance(self,msg.sender) - 1].addressed] = self.contractIndexList[msg.sender][revoked]; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete self.contractIndexList[msg.sender][self.contractAllowlist[msg.sender][self.contractIndexList[msg.sender][revoked]].addressed];
        self.contractAllowlist[msg.sender].pop();

        if (self.contractAllowlist[msg.sender].length > 0) {

            address[] memory addressed = new address[](self.contractAllowlist[msg.sender].length);
            for (uint256 i = 0; i < self.contractAllowlist[msg.sender].length; i++) {
                addressed[i] = self.contractAllowlist[msg.sender][i].addressed;
            }
                          
        } else {
            delete self.paths[revokee.urlPath];
        }  

        self.allowanceBalances[msg.sender]--;
    }
}