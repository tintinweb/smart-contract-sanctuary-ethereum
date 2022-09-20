// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import "./PresaleLaunchpadToken.sol";
import "./PublicsaleLaunchpadToken.sol";
import "./EVENTlaunchpadtoken.sol";
// import "hardhat/console.sol";






library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000
            )
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}





contract NCU_Launchpad{

    address payable  wallet =
    payable(0xc2c7d10B99bf936EffD3cFDD4f5e5f6A6acDDCd3);

    string  public contract_Name;
    address public tokenImplementation;
    address public tokenImplementation1;
    address public tokenImplementation2;
    address public ncuOwner;
    address public PresalecontractCreated;
    address public PublicsalecontractCreated;

    uint256 public presalecontractTax           = 2 ether;
    uint256 public publiccontractTax            = 2 ether;
    uint256 public generationTax                = 2 ether;
    uint256 public RankingNFTTax                = 2 ether;
    uint256 public uploadIPFStax                = 2 ether;
    uint256 public tax1155                      = 2 ether; 


    uint256 private counter = 1;

    struct UserDetails {
        address contractOwner;
        address contractAddress;
        string  contractName;
        uint256 createdTime;
        uint256 contractId;
        uint256 price;}

    struct otherDetails{
        string  contractName;
        uint256 createdTime;
        address user;
        uint256 price;}

    UserDetails        [] public userDataArray;
    otherDetails       [] public generationDataArray;
    otherDetails       [] public ipfsDataArray;
    otherDetails       [] public rankingNFTDataArray; 

    mapping(address => mapping (string  => UserDetails   ))            public user_data;
    mapping(address => mapping (string  => otherDetails  ))            public generationUser_data;
    mapping(address => mapping (string  => otherDetails  ))            public IPFSuser_data;
    mapping(address => mapping (string  => otherDetails  ))            public rankingUser_data;



    event TokenDeployed(address tokenAddress);

    constructor(){
        tokenImplementation     =   address (new PresaleLaunchpadToken());
        tokenImplementation1    =   address (new PublicsaleLaunchpadToken());
        tokenImplementation2    =   address (new EVENTlaunchpadtoken());

        contract_Name = "cloning factory";
        ncuOwner=msg.sender;}

    function setpresalecontractTax(uint256 _new)public {
        require(ncuOwner==msg.sender,"only owner");
        presalecontractTax=_new;}
    
    function setpubliccontractTax(uint256 _new)public {
        require(ncuOwner==msg.sender,"only owner");
        publiccontractTax=_new;}
    
    function setgenerationTax(uint256 _new)public {
        require(ncuOwner==msg.sender,"only owner");
        generationTax=_new;}
    
    function setRankingNFTTax(uint256 _new)public {
        require(ncuOwner==msg.sender,"only owner");
        RankingNFTTax=_new;}
    
    function setuploadIPFStax(uint256 _new)public {
        require(ncuOwner==msg.sender,"only owner");
        uploadIPFStax=_new;}

    function _transferOwnership(address _newOwner) public  {
        require(ncuOwner==msg.sender,"reverted");
        ncuOwner = _newOwner;}
        
    function setwallet(address payable _newwallet)public{
        require(ncuOwner==msg.sender,"reverted");
        wallet=_newwallet;}

    function walletforNCU()public view returns(address){
        return wallet;}
        
    function payment(string memory price)public payable returns(bool a) {

         // for cloning contract fee 
        if(keccak256(abi.encodePacked(price)) == keccak256(abi.encodePacked("clonepresale"))) {
           require(presalecontractTax == msg.value, "enter amount not correct");
           wallet.transfer(msg.value);
           return true;}
        
        else if(keccak256(abi.encodePacked(price)) == keccak256(abi.encodePacked("clonepublic"))){
           require(publiccontractTax == msg.value, "enter amount not correct");
           wallet.transfer(msg.value);
           return true;}

           else if(keccak256(abi.encodePacked(price)) == keccak256(abi.encodePacked("1155"))){
           require(tax1155 == msg.value, "enter amount not correct");
           wallet.transfer(msg.value);
           return true;}
           
        //    for generation fee  

        else if(keccak256(abi.encodePacked(price)) == keccak256(abi.encodePacked("generation"))){
           require(generationTax == msg.value, "enter amount not correct");
           wallet.transfer(msg.value);
            generationUser_data[msg.sender]['generation'] = otherDetails({
            contractName:'generation',
            createdTime:block.timestamp,
            user:msg.sender,
            price:generationTax

        });

            otherDetails memory _userDataInstance;
            _userDataInstance.contractName ='generation';
            _userDataInstance.createdTime = block.timestamp;
            _userDataInstance.user = msg.sender;
            _userDataInstance.price =generationTax;
            generationDataArray.push(_userDataInstance);
            return true;}

        // for rankingNFTS tax 

        else if(keccak256(abi.encodePacked(price)) == keccak256(abi.encodePacked("rankingNFTs"))){
           require(RankingNFTTax == msg.value, "enter amount not correct");
            wallet.transfer(msg.value);
            rankingUser_data[msg.sender]['generation'] = otherDetails({
            contractName:'rankingNFT',
            createdTime:block.timestamp,
            user:msg.sender,
            price:RankingNFTTax

        });

            otherDetails memory _userDataInstance;
            _userDataInstance.contractName ='rankingNFT';
            _userDataInstance.createdTime = block.timestamp;
            _userDataInstance.user = msg.sender;
            _userDataInstance.price =RankingNFTTax;
            rankingNFTDataArray.push(_userDataInstance);
            return true;}

           // for upload ipfs fee 

        else if(keccak256(abi.encodePacked(price)) == keccak256(abi.encodePacked("uploadipfs"))){
            require(uploadIPFStax == msg.value, "enter amount not correct");
            wallet.transfer(msg.value);
            IPFSuser_data[msg.sender]['uploadipfs'] = otherDetails({
            contractName:'uploadipfs',
            createdTime:block.timestamp,
            user:msg.sender,
            price:uploadIPFStax

        });

            otherDetails memory _userDataInstance;
            _userDataInstance.contractName ='uploadipfs';
            _userDataInstance.createdTime = block.timestamp;
            _userDataInstance.user = msg.sender;
            _userDataInstance.price =uploadIPFStax;
            ipfsDataArray.push(_userDataInstance);
           return true;}

        else{revert("reverted");}

    }

    function Clone1155(string memory _name,string memory _symbol,string memory _eventName,uint256 _eventSupply,uint256 _price,uint256 _startTime,uint256 _endTime,string memory _uri)
        public payable{

        require(payment('1155'),"reverted");
        address token = Clones.clone(tokenImplementation2);
        EVENTlaunchpadtoken(token).initialize(msg.sender,_name,_symbol,_eventName,_eventSupply,_price,_startTime,_endTime,_uri);
        user_data[msg.sender][_eventName] = UserDetails({
            contractOwner:      msg.sender,
            contractAddress:    token,
            contractName:       _eventName,
            createdTime:        block.timestamp,
            contractId:         counter,
            price:              tax1155
        });

        UserDetails memory _userDataInstance;
        _userDataInstance.contractOwner     = msg.sender;
        _userDataInstance.contractAddress   = token;
        _userDataInstance.contractName      = _eventName;
        _userDataInstance.createdTime       = block.timestamp;
        _userDataInstance.contractId        = counter;
        _userDataInstance.price             = tax1155;
        userDataArray.push(_userDataInstance);

        emit TokenDeployed(token);
        counter++;}
        
                
    function clonePresale(
        
        string      memory  _name,
        string      memory  _symbol,
        string      memory  _baseUri,
        uint256[7]  memory  _info,
        bytes32             _root,
        bool                _isJson)
         public payable 
    {
        require(payment('clonepresale'),"reverted");
        address token = Clones.clone(tokenImplementation);
        // maxSupply       =   info[0];
        // preSaleSupply   =   info[1];
        // maxPerTrans     =   info[2];
        // reserve         =   info[3];
        // price           =   info[4];
        // presalePrice    =   info[5];
        // maxPerWallet    =   info[6];
        PresaleLaunchpadToken(token).initialize(_name,_symbol,_baseUri,_root,_isJson,msg.sender,_info);
        user_data[msg.sender][_name] = UserDetails({
            contractOwner:      msg.sender,
            contractAddress:    token,
            contractName:       _name,
            createdTime:        block.timestamp,
            contractId:         counter,
            price:              presalecontractTax
        });

        UserDetails memory _userDataInstance;
        _userDataInstance.contractOwner     = msg.sender;
        _userDataInstance.contractAddress   = token;
        _userDataInstance.contractName      = _name;
        _userDataInstance.createdTime       = block.timestamp;
        _userDataInstance.contractId        = counter;
        _userDataInstance.price             = presalecontractTax;
        userDataArray.push(_userDataInstance);

        emit TokenDeployed(token);
        counter++;
           
         }





    function clonePublic(        
        string memory   _name,
        string memory   _symbol,
        string memory   _baseuri,
        uint256         _maxsupply,
        uint256         _maxPerTrans,
        uint256         _reserve,
        uint256         _price,
        bool            json)
        public payable{

        require(payment('clonepublic'),"reverted");
        address token = Clones.clone(tokenImplementation1);
        PublicsaleLaunchpadToken(token).initialize(
            _name,
            _symbol,
            _baseuri,
            _maxsupply,
            _maxPerTrans,
            _reserve,
            _price,
            json,
            msg.sender
        );
            
        // PublicsaleLaunchpadToken(token).initialize(msg.sender);
        user_data[msg.sender][_name] = UserDetails({
            contractOwner:      msg.sender,
            contractAddress:    token,
            contractName:       _name,
            createdTime:        block.timestamp,
            contractId:         counter,
            price:              publiccontractTax
        });

        UserDetails memory _userDataInstance;
        _userDataInstance.contractOwner     = msg.sender;
        _userDataInstance.contractAddress   = token;
        _userDataInstance.contractName      = _name;
        _userDataInstance.createdTime       = block.timestamp;
        _userDataInstance.contractId        = counter;
        _userDataInstance.price             = publiccontractTax;
        userDataArray.push(_userDataInstance);

        emit TokenDeployed(token);
        counter++;}
        
    function getTotalIndexw(address _owner)
        internal
        view
        returns (uint256 total)
    {
        uint256 countt = 0;

        for (uint256 index = 0; index < userDataArray.length; index++) {
            if (userDataArray[index].contractOwner == _owner) {
                countt += 1;
            }
        }
        return countt;
    }

    function getTotalIndexforgeneration(address _owner)
        internal
        view
        returns (uint256 total)
    {
        uint256 countt = 0;

        for (uint256 index = 0; index < generationDataArray.length; index++) {
            if (generationDataArray[index].user == _owner) {
                countt += 1;
            }
        }
        return countt;
    }

    function getTotalIndexforipfs(address _owner)
        internal
        view
        returns (uint256 total)
    {
        uint256 countt = 0;

        for (uint256 index = 0; index < ipfsDataArray.length; index++) {
            if (ipfsDataArray[index].user == _owner) {
                countt += 1;
            }
        }
        return countt;
    }


    function getTotalIndexforranking(address _owner)
        internal
        view
        returns (uint256 total)
    {
        uint256 countt = 0;

        for (uint256 index = 0; index < rankingNFTDataArray.length; index++) {
            if (rankingNFTDataArray[index].user == _owner) {
                countt += 1;
            }
        }
        return countt;
    }
    
    function getCompleteDataOfOwner(address owner)
        public
        view
        returns (
            
            address [] memory   contractAddresses,
            string  [] memory   _contractname,
            uint256 [] memory   contract_time,
            uint256 [] memory   price,
            uint256 [] memory   contractID,
            address [] memory   contractOwner
            
        )
    {
       
        uint256 dyanamicIndex = 0;

       
      
        address [] memory contractOwnerArray     = new address   [](getTotalIndexw(owner));
        address [] memory contractAddressArray   = new address   [](getTotalIndexw(owner));
        string  [] memory contractName           = new string    [](getTotalIndexw(owner));
        uint256 [] memory timeStampArray         = new uint256   [](getTotalIndexw(owner));
        uint256 [] memory _price                 = new uint256   [](getTotalIndexw(owner));
        uint256 [] memory _contractID            = new uint256   [](getTotalIndexw(owner));
        

      
        for (uint256 index = 0; index < userDataArray.length; index++) {
            if (userDataArray[index].contractOwner == owner) {
            
                contractAddressArray [dyanamicIndex]         = userDataArray [index].contractAddress;
                contractName         [dyanamicIndex]         = userDataArray [index].contractName;
                timeStampArray       [dyanamicIndex]         = userDataArray [index].createdTime;
                _price               [dyanamicIndex]         = userDataArray [index].price;
                _contractID          [dyanamicIndex]         = userDataArray [index].contractId; 
                contractOwnerArray   [dyanamicIndex]         = userDataArray [index].contractOwner; 

              
                dyanamicIndex++;
            }
        }
        return (contractAddressArray, contractName, timeStampArray,_price,_contractID,contractOwnerArray);
    }

    function getCompleteDataOfGeneration(address owner)
        public
        view
        returns (
            
         
            string  [] memory   _contractname,
            uint256 [] memory   contract_time,
            uint256 [] memory   price,
            address [] memory   contractOwner
             )
    {
       
        uint256 dyanamicIndex = 0;

        string  [] memory contractName           = new string    [](getTotalIndexforgeneration(owner));
        uint256 [] memory timeStampArray         = new uint256   [](getTotalIndexforgeneration(owner));
        uint256 [] memory _price                 = new uint256   [](getTotalIndexforgeneration(owner));
        address [] memory _user                  = new address   [](getTotalIndexforgeneration(owner));

        for (uint256 index = 0; index < generationDataArray.length; index++) {
            if (generationDataArray[index].user == owner) {

            
                contractName           [dyanamicIndex]         = generationDataArray [index].contractName;
                timeStampArray         [dyanamicIndex]         = generationDataArray [index].createdTime;
                _price                 [dyanamicIndex]         = generationDataArray [index].price;
                _user                  [dyanamicIndex]         = generationDataArray [index].user; 

                dyanamicIndex++;
            }
        }
        return (contractName, timeStampArray, _price,_user);
    }

    function getCompleteDataOfipfs(address owner)
        public
        view
        returns (
            
         
            string  [] memory   _contractname,
            uint256 [] memory   contract_time,
            uint256 [] memory   price,
            address [] memory   contractOwner
             )
    {
       
        uint256 dyanamicIndex = 0;

        string  [] memory contractName           = new string    [](getTotalIndexforgeneration(owner));
        uint256 [] memory timeStampArray         = new uint256   [](getTotalIndexforgeneration(owner));
        uint256 [] memory _price                 = new uint256   [](getTotalIndexforgeneration(owner));
        address [] memory _user                  = new address   [](getTotalIndexforgeneration(owner));

        for (uint256 index = 0; index < ipfsDataArray.length; index++) {
            if (ipfsDataArray[index].user == owner) {

            
                contractName           [dyanamicIndex]         = ipfsDataArray [index].contractName;
                timeStampArray         [dyanamicIndex]         = ipfsDataArray [index].createdTime;
                _price                 [dyanamicIndex]         = ipfsDataArray [index].price;
                _user                  [dyanamicIndex]         = ipfsDataArray [index].user; 

                dyanamicIndex++;
            }
        }
        return (contractName, timeStampArray, _price,_user);
    }


    function getCompleteDataOfrankingNFT(address owner)
        public
        view
        returns (
            string  [] memory   _contractname,
            uint256 [] memory   contract_time,
            uint256 [] memory   price,
            address [] memory   contractOwner
             )
    {
       
        uint256 dyanamicIndex = 0;

        string  [] memory contractName           = new string    [](getTotalIndexforranking(owner));
        uint256 [] memory timeStampArray         = new uint256   [](getTotalIndexforranking(owner));
        uint256 [] memory _price                 = new uint256   [](getTotalIndexforranking(owner));
        address [] memory _user                  = new address   [](getTotalIndexforranking(owner));

        for (uint256 index = 0; index < rankingNFTDataArray.length; index++) {
            if (rankingNFTDataArray[index].user == owner) {

            
                contractName           [dyanamicIndex]         = rankingNFTDataArray [index].contractName;
                timeStampArray         [dyanamicIndex]         = rankingNFTDataArray [index].createdTime;
                _price                 [dyanamicIndex]         = rankingNFTDataArray [index].price;
                _user                  [dyanamicIndex]         = rankingNFTDataArray [index].user; 

                dyanamicIndex++;
            }
        }
        return (contractName, timeStampArray, _price,_user);
    }


}