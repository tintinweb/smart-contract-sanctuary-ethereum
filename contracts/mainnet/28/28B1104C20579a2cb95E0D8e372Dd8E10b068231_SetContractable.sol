// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct AllowedContract {
    address addressed;
    string urlPath;
    string erc;
    uint256 balanceRequired;
    bool isStaking;
    bool isProxy;
    bool exists;
}

struct AllowedPath {
    address[] addresses;
    address wallet;
    string guild;
    bool exists;
}

struct ContractableData { 
    mapping(address => AllowedContract[]) contractAllowlist;
    mapping(string => AllowedPath) paths;
    mapping(string => AllowedPath) guildedPath;
    mapping(address => mapping(address => uint256)) contractIndexList;
    
    mapping(address => uint256) allowanceBalances;
}    

string constant DEFAULT_PATH="UNUSED_PATH";

library SetContractable {

    error PathAlreadyInUse(string path);   
    error PathDoesNotExist(string path);   
    error NonOwner(address requester, string path);  
    error WTF(bool success,address wtf);
    error IsNotAllowed(address requester, address contracted); 

    function transferPath(ContractableData storage self, address from, address to) public {
        if (self.contractAllowlist[from].length > 0) {
            string memory path = self.contractAllowlist[from][0].urlPath;
            string memory guild = internalPathAllows(self,path).guild;
            self.contractAllowlist[to] = self.contractAllowlist[from];
            AllowedPath memory newPath = AllowedPath(allowListToPath(self.contractAllowlist[to]),to,guild,true);
            for (uint256 i=0; i < self.contractAllowlist[to].length; i++) {
                self.contractIndexList[to][self.contractAllowlist[to][i].addressed] = i;
            }
            self.allowanceBalances[to] = self.allowanceBalances[from];
            revokePathInternal(self,path);
            self.paths[path] = newPath;
            if (bytes(guild).length > 0) {
                self.guildedPath[guild] = newPath;
            }
        }
    }
    
    function balanceOfAllowance(ContractableData storage self, address wallet) public view returns (uint256) {        
        return self.allowanceBalances[wallet];
    }     

    function allowances(ContractableData storage self, address wallet) public view returns (AllowedContract [] memory) {
        return self.contractAllowlist[wallet];
    }

    function addAllowance(ContractableData storage self, address allowed, string calldata urlPath, string calldata erc, uint256 balanceRequired, bool isStaking, bool isProxy) public {
        self.contractIndexList[msg.sender][allowed] = balanceOfAllowance(self,msg.sender);
        self.contractAllowlist[msg.sender].push(AllowedContract(allowed,urlPath,erc,balanceRequired,isStaking,isProxy,true));        
        self.allowanceBalances[msg.sender]++;
    }

    function allowContract(
        ContractableData storage self, 
        address allowed, 
        string calldata urlPath, 
        string calldata erc,
        string calldata guild,
        uint256 balanceRequired,
        bool isStaking, 
        bool isProxy) public {
        if (self.paths[urlPath].exists) {
            if (self.paths[urlPath].wallet != msg.sender) {
                revert PathAlreadyInUse(urlPath);
            }
        } else if (balanceOfAllowance(self, msg.sender) > 0) {
            if (!self.paths[urlPath].exists) {
                for (uint256 i = 0; i < balanceOfAllowance(self, msg.sender); i++) {
                    AllowedContract storage existing = self.contractAllowlist[msg.sender][i];
                    if (self.paths[existing.urlPath].exists) {
                        delete self.paths[existing.urlPath];
                    }
                    existing.urlPath = urlPath;
                }
            }
        } 
        
        if (balanceOfAllowance(self,msg.sender) != 0) {
            uint256 index = self.contractIndexList[msg.sender][allowed];
            if (self.contractAllowlist[msg.sender][index].addressed != allowed) { 
                addAllowance(self,allowed,urlPath,erc,balanceRequired,isStaking,isProxy); 
            }
        } else {
            addAllowance(self,allowed,urlPath,erc,balanceRequired,isStaking,isProxy); 
        }   
        
        address[] memory addressed = new address[](balanceOfAllowance(self, msg.sender));
        for (uint256 i = 0; i < balanceOfAllowance(self, msg.sender); i++) {
            addressed[i] = self.contractAllowlist[msg.sender][i].addressed;
        }

        self.paths[urlPath] = AllowedPath(addressed,msg.sender,guild,true);
        if (bytes(guild).length > 1) {
            self.guildedPath[guild] = self.paths[urlPath];
        }        
    } 

    function removeAllowance(ContractableData storage self, address allowed, string calldata urlPath, string calldata erc, uint256 balanceRequired, bool isStaking, bool isProxy) public {
        self.contractIndexList[msg.sender][allowed] = balanceOfAllowance(self,msg.sender);
        self.contractAllowlist[msg.sender].push(AllowedContract(allowed,urlPath,erc,balanceRequired,isStaking,isProxy,true));        
        self.allowanceBalances[msg.sender]++;
    }    

    function revokePath(ContractableData storage self, string calldata path) public {
        AllowedPath memory allowed = pathAllows(self,path);
        string memory memPath = path;
        if (allowed.wallet != msg.sender) {
            revert NonOwner(msg.sender,path);
        }
        revokePathInternal(self,memPath);
    }

    function revokePathInternal(ContractableData storage self, string memory path) public {
        for (uint256 i = self.contractAllowlist[msg.sender].length-1; i > 0; i--) {
            delete self.contractIndexList[msg.sender][self.contractAllowlist[msg.sender][i].addressed];
            self.contractAllowlist[msg.sender].pop();
        }
        delete self.contractIndexList[msg.sender][self.contractAllowlist[msg.sender][0].addressed];
        self.contractAllowlist[msg.sender].pop();    
        string memory guild = self.paths[path].guild;    
        delete self.paths[path]; 
        if (bytes(guild).length > 0) {
            delete self.guildedPath[guild];
        }
        self.allowanceBalances[msg.sender] = 0;
        self.paths[path] = AllowedPath(new address[](0),msg.sender,guild,false);
        if (bytes(guild).length > 0) {
            self.guildedPath[guild] = AllowedPath(new address[](0),msg.sender,guild,false);
        }
    }    

    function allowListToPath(AllowedContract[] storage allowed) internal view returns (address[] memory){
        address[] memory addresses = new address[](allowed.length);
        for (uint256 i=0; i < allowed.length; i++) {
            addresses[i] = allowed[i].addressed;
        }
        return addresses;
    }

    function pathAllows(ContractableData storage self, string calldata path) public view returns (AllowedPath memory) {
        if (!self.paths[path].exists) {
            address[] memory defaultAddress = new address[](0);
            return AllowedPath(defaultAddress,address(0),"",false);
        }
        return self.paths[path];
    }
    function findGuildPath(ContractableData storage self, string calldata guild) public view returns (AllowedPath memory) {
        if (!self.guildedPath[guild].exists) {
            address[] memory defaultAddress = new address[](0);
            return AllowedPath(defaultAddress,address(0),"",false);
        }
        return self.guildedPath[guild];
    }
    function internalPathAllows(ContractableData storage self, string memory path) public view returns (AllowedPath memory) {
        if (!self.paths[path].exists) {
            address[] memory defaultAddress = new address[](0);
            return AllowedPath(defaultAddress,address(0),"",false);
        }
        return self.paths[path];
    }    
}