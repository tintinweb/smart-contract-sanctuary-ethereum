// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import "./PresaleLaunchpadToken.sol";
import "./PublicsaleLaunchpadToken.sol";





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





contract NCU_Launchpad  {

    
    string  public contract_name;
    address public tokenImplementation;
    address public tokenImplementation1;
    address public NCUowner;
    address public PresalecontractCreated;
    address public PublicsalecontractCreated;

    uint256 public presalecontractTax           = 2 ether;
    uint256 public publiccontractTax            = 2 ether;
    uint256 public generationTax                = 2 ether;
    uint256 public RankingNFTTax                = 2 ether;
    uint256 public uploadIPFStax                = 2 ether;

    address payable wallet =
        payable(0xc2c7d10B99bf936EffD3cFDD4f5e5f6A6acDDCd3);
    uint256 private counter = 1;

    struct UserDetails {
        address contractOwner;
        address contractAddress;
        string  contractName;
        uint256 createdTime;
        uint256 contractId;
        uint256 price;
    }


    struct otherDetails{
        string  contractName;
        uint256 createdTime;
        address user;
        uint256 price;
    }


    UserDetails        [] public userDataArray;
    otherDetails       [] public generationDataArray;
    otherDetails       [] public ipfsDataArray;
    otherDetails       [] public rankingNFTDataArray; 

    // mapping(address => contract_Data) data;  
    mapping(address => mapping (string  => UserDetails  ))            public user_data;
    mapping(address => mapping (string  => otherDetails ))            public generationUser_data;
    mapping(address => mapping (string  => otherDetails ))            public IPFSuser_data;
    mapping(address => mapping (string  => otherDetails ))            public rankingUser_data;
    // mapping(address => address) public newContractAddress;


    event TokenDeployed(address tokenAddress);






    // function checkData(address user)public view returns(contract_Data  memory ) {
    // //    contract_Data storage  obj =new contract_Data;
    //     return data[user];
    // }


    // event display(address indexed owner,uint256 indexed time,uint256 indexed payment,string payment_type);
    // function checkData1(address lodhi)public  {

    //     for(uint i=0;i<data[lodhi].user.length;i++){
            
    //         emit display(
    //         data[lodhi].user[i],
    //         data[lodhi].time[i],
    //         data[lodhi].payment[i],
    //         data[lodhi].payment_type[i]);

    //     }
    // }


    constructor() {
        tokenImplementation     =   address(new PresaleLaunchpadToken());
        tokenImplementation1    =   address(new PublicsaleLaunchpadToken());
        contract_name = "cloning factory";
        NCUowner=msg.sender;

    }


     function setpresalecontractTax(uint256 a)public {
        require(NCUowner==msg.sender,"only owner");
        presalecontractTax=a;
    }
       function setpubliccontractTax(uint256 a)public {
        require(NCUowner==msg.sender,"only owner");
        publiccontractTax=a;
    }
       function setgenerationTax(uint256 a)public {
        require(NCUowner==msg.sender,"only owner");
        generationTax=a;
    }
       function setRankingNFTTax(uint256 a)public {
        require(NCUowner==msg.sender,"only owner");
        RankingNFTTax=a;
    }
       function setuploadIPFStax(uint256 a)public {
        require(NCUowner==msg.sender,"only owner");
        uploadIPFStax=a;
    }

    function _transferOwnership(address newOwner) public  {
        require(NCUowner==msg.sender,"reverted");
        NCUowner = newOwner;
        
    }

    function setwallet(address payable  a)public{
        require(NCUowner==msg.sender,"reverted");
        wallet=a;
    }




    function payment(string memory price)public payable returns(bool a) {

         // for contract fee 
        if(keccak256(abi.encodePacked(price)) == keccak256(abi.encodePacked("clonepresale"))) {
           require(presalecontractTax == msg.value, "enter amount not correct");
           wallet.transfer(msg.value);
           return true;}
        
        else if(keccak256(abi.encodePacked(price)) == keccak256(abi.encodePacked("clonepublic"))){
           require(publiccontractTax == msg.value, "enter amount not correct");
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
        
        


   


    function clonePresale(
        
        string memory   _name,
        string memory   _symbol,
        uint256         _maxsupply1,
        uint256         _preSaleSupply,
        uint256         _maxPerTrans,
        uint256         _reserve,
        uint256         _price,
        uint256         _presalePrice,
        string memory   _baseuri,
        uint256         _maxPerWallet,
        bytes32         _root
    ) public payable 
    {
        require(payment('clonepresale'),"reverted");
        address token = Clones.clone(tokenImplementation);
        // PresalecontractCreated=token;
        PresaleLaunchpadToken(token).contractDetails(
            _name,
            _symbol,
            _maxsupply1,
            _preSaleSupply,
            _maxPerTrans,
            _reserve,
            _price,
            _presalePrice,
            _baseuri,
            _maxPerWallet,
            _root
        );
        PresaleLaunchpadToken(token).initialize(msg.sender);
        // PresaleLaunchpadToken(token).transferOwnership(msg.sender);
        // require(tax == msg.value, "enter amount not correct");
        // wallet.transfer(msg.value);

        // newContractAddress[msg.sender] = token;

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
        // getCompleteDataOfOwner(msg.sender);
        // presale();
        

            // // enter contract details
            // data[msg.sender].user.push(msg.sender);
            // data[msg.sender].time.push(block.timestamp);
            // data[msg.sender].payment.push(2);
            // data[msg.sender].payment_type.push("clonePresale");
          
        


    }






  


    function clonePublic(
        
        string memory _name,
        string memory _symbol,
        uint256 _maxsupply1,
        uint256 _maxPerTrans,
        uint256 _reserve,
        uint256 _price,
        string memory _baseuri
    
    ) public payable  {
        require(payment('clonepublic'),"reverted");
        address token = Clones.clone(tokenImplementation1);
        // PublicsalecontractCreated=token;
        PublicsaleLaunchpadToken(token).contractDetails(
            _name,
            _symbol,
            _maxsupply1,
            _maxPerTrans,
            _reserve,
            _price,
            _baseuri
          
        );
        PresaleLaunchpadToken(token).initialize(msg.sender);
      
        // require(tax == msg.value, "enter amount not correct");
        // wallet.transfer(msg.value);
        // newContractAddress[recipient1] = token;
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
        counter++;
        // publicsale();
       
    }

    // function presale()public view returns(address haris){
    //     return PresalecontractCreated;
    // }

    //    function publicsale()public view returns(address haris){
    //     return PublicsalecontractCreated;
    // }













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



    // function getcontractID(address owner)
    //     public
    //     view
    //     returns (uint256[] memory id)
    // {
    //     uint256 dyanamicIndex = 0;
    //     uint256[] memory contractIdArray = new uint256[](getTotalIndexw(owner));

    //     for (uint256 index = 0; index < userDataArray.length; index++) {
    //         if (userDataArray[index].contractOwner == owner) {
    //             contractIdArray[dyanamicIndex] = userDataArray[index].contractId;
    //             dyanamicIndex++;
    //         }
    //     }
    //     return (contractIdArray);
    // }










}