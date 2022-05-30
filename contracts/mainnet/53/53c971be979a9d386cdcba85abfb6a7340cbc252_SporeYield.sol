/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//////////////////////////////////////////////////
//      ____               __  ___     __   __  //
//     / __/__  ___  ______\ \/ (_)__ / /__/ /  //
//    _\ \/ _ \/ _ \/ __/ -_)  / / -_) / _  /   //
//   /___/ .__/\___/_/  \__//_/_/\__/_/\_,_/    //
//      /_/                                     //
//                        by 0xInuarashi.eth    //
//////////////////////////////////////////////////

// Open0x ECDSA 
library ECDSA {

    ///// Signer Address Recovery /////
    
    // In its pure form, address recovery requires the following parameters
    // params: hash, v, r ,s

    // First, we define some standard checks
    function checkValidityOf_s(bytes32 s) public pure returns (bool) {
        if (uint256(s) > 
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("recoverAddressFrom_hash_v_r_s: Invalid s value");
        }
        return true;
    }
    function checkValidityOf_v(uint8 v) public pure returns (bool) {
        if (v != 27 && v != 28) {
            revert("recoverAddressFrom_hash_v_r_s: Invalid v value");
        }
        return true;
    }

    // Then, we first define the pure form of recovery.
    function recoverAddressFrom_hash_v_r_s(bytes32 hash, uint8 v, bytes32 r,
    bytes32 s) public pure returns (address) {
        // First, we need to make sure that s and v are in correct ranges
        require(checkValidityOf_s(s) && checkValidityOf_v(v));

        // call recovery using solidity's built-in ecrecover method
        address _signer = ecrecover(hash, v, r, s);
        
        require(_signer != address(0),
            "_signer == address(0)");

        return _signer;
    }

    // There are also other ways to receive input without v, r, s values which
    // you will need to parse the unsupported data to find v, r, s and then
    // use those to call ecrecover.

    // For these, there are 2 other methods:
    // 1. params: hash, r, vs
    // 2. params: hash, signature

    // These then return the v, r, s values required to use recoverAddressFrom_hash_v_r_s

    // So, we will parse the first method to get v, r, s
    function get_v_r_s_from_r_vs(bytes32 r, bytes32 vs) public pure 
    returns (uint8, bytes32, bytes32) {
        bytes32 s = vs & 
            bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        
        uint8 v = uint8((uint256(vs) >> 255) + 27);

        return (v, r, s);
    }

    function get_v_r_s_from_signature(bytes memory signature) public pure 
    returns (uint8, bytes32, bytes32) {
        // signature.length can be 64 and 65. this depends on the method
        // the standard is 65 bytes1, eip-2098 is 64 bytes1.
        // so, we need to account for these differences

        // in the case that it is a standard 65 bytes1 signature
        if (signature.length == 65) {
            uint8 v;
            bytes32 r;
            bytes32 s;

            // assembly magic
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }

            // return the v, r, s 
            return (v, r, s);
        }

        // in the case that it is eip-2098 64 bytes1 signature
        else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;

            // assembly magic 
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }

            return get_v_r_s_from_r_vs(r, vs);
        }

        else {
            revert("Invalid signature length");
        }
    }

    // ///// Embedded toString /////

    // // We need this in one of the methods of returning a signed message below.

    // function _toString(uint256 value_) internal pure returns (string memory) {
    //     if (value_ == 0) { return "0"; }
    //     uint256 _iterate = value_; uint256 _digits;
    //     while (_iterate != 0) { _digits++; _iterate /= 10; } // get digits in value_
    //     bytes memory _buffer = new bytes(_digits);
    //     while (value_ != 0) { _digits--; _buffer[_digits] = bytes1(uint8(
    //         48 + uint256(value_ % 10 ))); value_ /= 10; } // create bytes of value_
    //     return string(_buffer); // return string converted bytes of value_
    // }

    // ///// Generation of Hashes /////
    
    // // We need these methods because these methods are used to compare
    // // hash generated off-chain to hash generated on-chain to cross-check the
    // // validity of the signatures

    // // 1. A bytes32 hash to generate a bytes32 hash embedded with prefix
    // // 2. A bytes memory s to generate a bytes32 hash embedded with prefix
    // // 3. A bytes32 domain seperator and bytes32 structhash to generate 
    // //      a bytes32 hash embedded with prefix

    // // See: EIP-191
    // function toEthSignedMessageHashBytes32(bytes32 hash) public pure 
    // returns (bytes32) {
    //     return keccak256(abi.encodePacked(
    //         // Magic prefix determined by the devs
    //         "\x19Ethereum Signed Message:\n32",
    //         hash
    //     ));
    // }

    // // See: EIP-191
    // function toEthSignedMessageHashBytes(bytes memory s) public pure
    // returns (bytes32) {
    //     return keccak256(abi.encodePacked(
    //         // Another magic prefix determined by the devs
    //         "\x19Ethereum Signed Message:\n", 
    //         // The bytes length of s
    //         _toString(s.length),
    //         // s itself
    //         s
    //     ));
    // }

    // // See: EIP-712
    // function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) public
    // pure returns (bytes32) {
    //     return keccak256(abi.encodePacked(
    //         // Yet another magic prefix determined by the devs
    //         "\x19\x01",
    //         // The domain seperator (EIP-712)
    //         domainSeparator,
    //         // struct hash
    //         structHash
    //     ));
    // }
}

abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

interface iSpore {
    function transfer(address to_, uint256 amount_) external;
    function mintAsController(address to_, uint256 amount_) external;
}

interface iNFF {
    function totalSupply() external view returns (uint256);
    function balanceOf(address address_) external view returns (uint256);
    function ownerOf(uint256 tokenId_) external view returns (address);
    function walletOfOwner(address address_) external view returns (uint256[] memory);

    function transferFrom(address from_, address to_, uint256 tokenId_) external;
}


contract SporeYield is Ownable {

    // Events
    event Claim(address to_, uint256[] indexes_, uint256 totalClaimed);

    // Interfaces
    // NOTE: change this address (After spore token deployment)
    iSpore public Spore = iSpore(0xD5E6d515b18004d0d4b2813078988cD67aDa6D7C); 
    function setSpore(address address_) external onlyOwner { 
        Spore = iSpore(address_); 
    }

    iNFF public NFFGenerative = iNFF(0x90ee3Cf59FcDe2FE11838b9075Ea4681462362F1);
    function setNFFGenerative(address address_) external onlyOwner {
        NFFGenerative = iNFF(address_);
    }

    iNFF public NFFGenesis = iNFF(0x5f47079D0E45d95f5d5167A480B695883C4E47D9);
    function setNFFGenesis(address address_) external onlyOwner {
        NFFGenesis = iNFF(address_);
    }

    // // Constructor to set the contract addresses (optional)
    // constructor(address spore, address generative, address genesis) Ownable() {
    //     Spore = iSpore(spore);
    //     NFFGenerative = iNFF(generative);
    //     NFFGenesis = iNFF(genesis);
    // }

    // Times
    uint256 public yieldStartTime = 1653264000; // May 23 2022 14:00:00 GMT+0000
    uint256 public yieldEndTime = 1732060800; // November 20 2024 14:00:00 GMT+0000
    function setYieldEndTime(uint256 yieldEndTime_) external onlyOwner { 
        yieldEndTime = yieldEndTime_; }

    // Yield Info
    mapping(uint256 => uint256) public indexToYield;
    
    // @dev this is a function to override yield setting. use it with caution.
    function O_setIndexToYields(uint256[] calldata tokenIds_,
    uint256[] calldata yields_) external onlyOwner {
        require(tokenIds_.length == yields_.length,
            "Array lengths mismatch!");
        
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            indexToYield[tokenIds_[i]] = yields_[i];
        }
    }

    // Yield Database
    mapping(uint256 => uint256) public indexToClaimedTimestamp;

    // // Timestamp Controller (Optional)

    // mapping(address => bool) public addressToTimestampControllers;

    // // Timestamp Controllers can be given externally to other addresses 
    // // in order to modify the timestamp of mappings. 
    // // Only use if you know what you are doing. 
    // modifier onlyTimestampControllers {
    //     require(addressToTimestampControllers[msg.sender],
    //         "Invalid timestamp controller!");
    //     _;
    // }

    // function controllerSetClaimTimestamps(uint256[] memory indexes_, 
    // uint256[] memory timestamps_) public onlyTimestampControllers {
    //     for (uint256 i = 0; i < indexes_.length; i++) {
    //         // The timestamp set must never be below the yieldStartTime
    //         require(yieldStartTime <= timestamps_[i],
    //             "Timestamp set below yieldStartTime!");

    //         indexToClaimedTimestamp[indexes_[i]] = timestamps_[i];
    //     }
    // }
    // ////

    // Internal Calculators
    function _getCurrentTimeOrEnded() public view returns (uint256) {
        // Return block.timestamp if it's lower than yieldEndTime, otherwise
        // return yieldEndTime instead.
        return block.timestamp < yieldEndTime ?
            block.timestamp : yieldEndTime;
    }
    function _getTimestampOfToken(uint256 index_) public view returns (uint256) {
        // return indexToClaimedTimestamp[index_] == 0 ?

        // Adjusted to yieldStartTime and hardcoded to save gas
        return indexToClaimedTimestamp[index_] < 1653264000 ?
            yieldStartTime : indexToClaimedTimestamp[index_];
    }

    // Yield Accountants
    function getPendingTokens(uint256 index_) public view returns (uint256) {

        // First, grab the timestamp of the token
        uint256 _lastClaimedTimestamp = _getTimestampOfToken(index_);

        // Then, we grab the current timestamp or ended
        uint256 _timeCurrentOrEnded = _getCurrentTimeOrEnded();

        // Lastly, we calculate the time-units in seconds of elapsed time
        uint256 _timeElapsed = _timeCurrentOrEnded - _lastClaimedTimestamp;

        // Now, return the calculation of yield
        require(indexToYield[index_] != 0,
            "Yield Lookup not Initialized!");
        
        return (_timeElapsed * indexToYield[index_]) / 1 days;
    }
    function getInitializedTokenYields(uint256[] memory indexes_) public
    view returns (uint256[] memory) {
        uint256[] memory _tokenYields = new uint256[](indexes_.length);
        for (uint256 i = 0; i < indexes_.length; i++) {
            _tokenYields[i] = indexToYield[indexes_[i]];
        }
        // Then, return the final value
        return _tokenYields;
    }
    function getPendingTokensMany(uint256[] memory indexes_) public
    view returns (uint256) {
        // First, create an empty MSTORE to store the pending tokens tracker
        uint256 _pendingTokens;
        // Now, run a loop through the entire indexes array to add it
        for (uint256 i = 0; i < indexes_.length; i++) {
            _pendingTokens += getPendingTokens(indexes_[i]);
        }

        // Then, return the final value
        return _pendingTokens;
    }

    function getPendingTokensWithUninitialized(uint256 index_, uint256 yieldRate_) public view returns (uint256) {

        // First, grab the timestamp of the token
        uint256 _lastClaimedTimestamp = _getTimestampOfToken(index_);

        // Then, we grab the current timestamp or ended
        uint256 _timeCurrentOrEnded = _getCurrentTimeOrEnded();

        // Lastly, we calculate the time-units in seconds of elapsed time
        uint256 _timeElapsed = _timeCurrentOrEnded - _lastClaimedTimestamp;

        // Now, return the calculation of yield
        return (_timeElapsed * yieldRate_) / 1 days;
    }
    function getPendingTokensManyWithUninitialized(uint256[] memory indexes_, uint256[] calldata yieldRates_) public
    view returns (uint256) {
        require(indexes_.length == yieldRates_.length);

        // First, create an empty MSTORE to store the pending tokens tracker
        uint256 _pendingTokens;

        // Now, run a loop through the entire indexes array to add it
        for (uint256 i = 0; i < indexes_.length; i++) {
            _pendingTokens += getPendingTokensWithUninitialized(indexes_[i], yieldRates_[i]);
        }

        // Then, return the final value
        return _pendingTokens;
    }

    // Internal Timekeepers
    function _updateTimestampOfTokens(uint256[] memory indexes_) internal {
        // Get the timestamp using internal function
        uint256 _timeCurrentOrEnded = _getCurrentTimeOrEnded();
        
        // Loop through the entire indexes_ array and set the timestamps
        for (uint256 i = 0; i < indexes_.length; i++) {
            // Prevents duplicate setting of same token in the same block
            require(indexToClaimedTimestamp[indexes_[i]] != _timeCurrentOrEnded,
                "Unable to set timestamp duplication in the same block!");

            indexToClaimedTimestamp[indexes_[i]] = _timeCurrentOrEnded;
        }
    }

    function getIndexOfTokens(address[] memory contracts_,
    uint256[] memory tokenIds_) public view returns (uint256[] memory) {

        // Make sure the array lengths are equal
        require(contracts_.length == tokenIds_.length,
            "getIndexOfTokens(): Array lengths mismatch!");
        
        // MSTORE to save GAS
        uint256 _items = tokenIds_.length;
        address _NFFGenerativeAddress = address(NFFGenerative);
        address _NFFGenesisAddress = address(NFFGenesis);

        // Make sure all items are of supported contracts
        for (uint256 i = 0; i < _items; i++) {
            require(contracts_[i] == _NFFGenerativeAddress ||
                contracts_[i] == _NFFGenesisAddress,
                "getIndexOfTokens(): Unsupported Contract!");
        }
        
        // MSTORE _indexes to return
        uint256[] memory _indexes = new uint256[](_items);

        // Generate the index array
        for (uint256 i = 0; i < _items; i++) {
            // Generate the offset. If generative, offeset is 10000, else, it's 0.
            uint256 _offset = contracts_[i] == _NFFGenerativeAddress ? 0 : 10000;
            _indexes[i] = tokenIds_[i] + _offset;
        }

        // Return the _indexes array
        return _indexes;
    }

    function claim(uint256[] calldata tokenIds_) 
    public returns (uint256) {
        // Make sure the sender owns all the tokens
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            if(tokenIds_[i] < 10000)
            {
                require(msg.sender == NFFGenerative.ownerOf(tokenIds_[i]),
                    "You do not own this token!");
            }
            else
            {
                require(msg.sender == NFFGenesis.ownerOf(tokenIds_[i] - 10000),
                    "You do not own this token!");
            }
        }

        // Calculate the total pending tokens to be claimed from index array
        uint256 _pendingTokens = getPendingTokensMany(tokenIds_);

        // Set the new timestamp of the tokens
        // @dev: this step will fail if duplicate tokenIds_ are passed in
        _updateTimestampOfTokens(tokenIds_);

        // Mint the total tokens for the msg.sender
        Spore.mintAsController(msg.sender, _pendingTokens);

        // Emit claim of total tokens
        emit Claim(msg.sender, tokenIds_, _pendingTokens);

        // Return the claim amount
        return _pendingTokens;
    }

    // NOTE: change this to the correct spore data signer!
    address public sporeDataSigner = 0xe4535f8EE9b374BBc2c5A57B35f09A89fe43a657; 

    function setSporeDataSigner(address address_) public onlyOwner {
        sporeDataSigner = address_;
    }

    // Data initializer controllers
    mapping(address => bool) public addressToYieldDataInitializers;

    function setYieldDataInitializers(address[] calldata initializers_,
    bool bool_) external onlyOwner {
        for (uint256 i = 0; i < initializers_.length; i++) {
            addressToYieldDataInitializers[initializers_[i]] = bool_;
        }
    }

    modifier onlyYieldDataInitializer {
        require(addressToYieldDataInitializers[msg.sender],
            "Invalid yield data initializer!");
        _;
    }

    function controllerInitializeYieldDatas(uint256[] memory indexes_, 
    uint256[] memory yieldDatas_, bytes[] memory signatures_) public 
    onlyYieldDataInitializer {
        _initializeYieldDatas(indexes_, yieldDatas_, signatures_);
    }
    ////

    // Core initialization logic
    function _initializeYieldDatas(uint256[] memory indexes_, 
    uint256[] memory yieldDatas_, bytes[] memory signatures_) internal {
        
        // In order to effectively use this function, the index and yielddata
        // array must be passed in as uninitialized-FIRST with signature
        // length only in the amount of uninitialized yield datas.

        // The function itself supports input of both uninitialized and initialized
        // tokens based on signature length.
        
        // Make sure all the indexes to yieldDatas is valid through ECDSA 
        for (uint256 i = 0; i < signatures_.length; i++) {
            // make sure the yieldDatas_[i] and signatures_[i] is correct
            // thus we need to use get_v_r_s_from_signature function before
            // address recovery
            (uint8 v, bytes32 r, bytes32 s) = 
                ECDSA.get_v_r_s_from_signature(signatures_[i]);

            // Create the token data hash to use with ecrecover
            bytes32 _tokenDataHash = keccak256(abi.encodePacked(
                indexes_[i],
                yieldDatas_[i]
            ));

            require(sporeDataSigner == 
                ECDSA.recoverAddressFrom_hash_v_r_s(_tokenDataHash, v, r, s),
                "Invalid signer");

            // Initialize them if empty
            if (indexToYield[indexes_[i]] == 0) { 
                // 10 Ether is the maximum per day as yield data is concerned.
                // We added leeway for 20 Ether in case any future changes.
                // We hardcoded this to save on gas.
                require(20 ether >= yieldDatas_[i],
                    "Yield value not intended!");
                
                indexToYield[indexes_[i]] = yieldDatas_[i];
            }
        }
    }

    function claimWithInitializable(  
    uint256[] calldata tokenIds_, uint256[] calldata yieldDatas_,
    bytes[] calldata signatures_) external returns (uint256) {
        require(tokenIds_.length >= yieldDatas_.length &&
            tokenIds_.length >= signatures_.length,
            "Array Lengths Mismatch!");
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            if(tokenIds_[i] < 10000)
            {
                require(msg.sender == NFFGenerative.ownerOf(tokenIds_[i]),
                    "You do not own this token!");
            }
            else
            {
                require(msg.sender == NFFGenesis.ownerOf(tokenIds_[i] - 10000),
                    "You do not own this token!");
            }
        }
        // Initialize the Yield Datas
        _initializeYieldDatas(tokenIds_, yieldDatas_, signatures_);

        // Calculate the total pending tokens to be claimed from index array
        // Without _initializeYieldDatas, this function would revert.
        uint256 _pendingTokens = getPendingTokensMany(tokenIds_);

        // Set the new timestamp of the tokens
        // If there are duplicate indexes in the array, this function will revert.
        _updateTimestampOfTokens(tokenIds_);

        // Mint the total tokens for the msg.sender
        Spore.mintAsController(msg.sender, _pendingTokens);

        // Emit claim of total tokens
        emit Claim(msg.sender, tokenIds_, _pendingTokens);

        // Return token amount
        return _pendingTokens;
    }

    // Public View Functions for Helpers
    function walletOfGenesis(address address_) public view 
    returns (uint256[] memory) {
        return NFFGenesis.walletOfOwner(address_);
    }
    function walletOfGenerative(address address_) public view 
    returns (uint256[] memory) {
        return NFFGenerative.walletOfOwner(address_);
    }

    function walletIndexOfOwner(address address_) public view 
    returns (uint256[] memory) {
        // For this function, we want to return a unified index 
        uint256 _genesisBalance = NFFGenesis.balanceOf(address_);
        uint256 _generativeBalance = NFFGenerative.balanceOf(address_);
        uint256 _totalBalance = _genesisBalance + _generativeBalance;
        
        // Create the indexes based on a combined balance to input datas
        uint256[] memory _indexes = new uint256[] (_totalBalance);

        // Call both wallet of owners
        uint256[] memory _walletOfGenesis = walletOfGenesis(address_);
        uint256[] memory _walletOfGenerative = walletOfGenerative(address_);

        // Now start inserting into the index with both wallets with offsets
        uint256 _currentIndex;
        for (uint256 i = 0; i < _walletOfGenerative.length; i++) {
            // Generative has an offset of 0
            _indexes[_currentIndex++] = _walletOfGenerative[i];
        }
        for (uint256 i = 0; i < _walletOfGenesis.length; i++) {
            // Genesis has an offset of 10000
            _indexes[_currentIndex++] = _walletOfGenesis[i] + 10000;
        }

        return _indexes;
    }
}