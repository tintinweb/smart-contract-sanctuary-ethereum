// SPDX-License-Identifier: MIT

/*

8888888                                    888    888b    888                                 
  888                                      888    8888b   888                                 
  888                                      888    88888b  888                                 
  888   88888b.  .d8888b   .d88b.  888d888 888888 888Y88b 888  8888b.  88888b.d88b.   .d88b.  
  888   888 "88b 88K      d8P  Y8b 888P"   888    888 Y88b888     "88b 888 "888 "88b d8P  Y8b 
  888   888  888 "Y8888b. 88888888 888     888    888  Y88888 .d888888 888  888  888 88888888 
  888   888  888      X88 Y8b.     888     Y88b.  888   Y8888 888  888 888  888  888 Y8b.     
8888888 888  888  88888P'  "Y8888  888      "Y888 888    Y888 "Y888888 888  888  888  "Y8888  
                                                                                              


  ___                    _           _      __             _   _                                                           
 / _ \                  (_)         | |    / _|           | | | |                                                          
/ /_\ \  _ __  _ __ ___  _  ___  ___| |_  | |_ ___  _ __  | |_| |__   ___                                                  
|  _  | | '_ \| '__/ _ \| |/ _ \/ __| __| |  _/ _ \| '__| | __| '_ \ / _ \                                                 
| | | | | |_) | | | (_) | |  __| (__| |_  | || (_) | |    | |_| | | |  __/                                                 
\_| |_/ | .__/|_|  \___/| |\___|\___|\__| |_| \___/|_|     \__|_| |_|\___|                                                 
 _____  | |  __        _/ |    _           _         _____ _           _ _                         _____ _____ _____ _____ 
|_   _| |_| / _|      |__/    | |         (_)       /  __ | |         | | |                       / __  |  _  / __  / __  \
  | | _ __ | |_ _ __ __ _  ___| |__   __ _ _ _ __   | /  \| |__   __ _| | | ___ _ __   __ _  ___  `' / /| |/' `' / /`' / /'
  | || '_ \|  _| '__/ _` |/ __| '_ \ / _` | | '_ \  | |   | '_ \ / _` | | |/ _ | '_ \ / _` |/ _ \   / / |  /| | / /   / /  
 _| || | | | | | | | (_| | (__| | | | (_| | | | | | | \__/| | | | (_| | | |  __| | | | (_| |  __/ ./ /__\ |_/ ./ /__./ /___
 \___|_| |_|_| |_|  \__,_|\___|_| |_|\__,_|_|_| |_|  \____|_| |_|\__,_|_|_|\___|_| |_|\__, |\___| \_____/\___/\_____\_____/
                                                                                       __/ |                               
                                                                                      |___/                                


/////////////////// Team Reveals ///////////////////
// By @Thomas Keiser, Julien Soyer & Aloïs Moubax //
////////////////////////////////////////////////////

*/

pragma solidity ^0.8.4;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Smartcontract is Ownable {
    
    
/*
______                              _                
| ___ \                            | |               
| |_/ /_ _ _ __ __ _ _ __ ___   ___| |_ ___ _ __ ___ 
|  __/ _` | '__/ _` | '_ ` _ \ / _ \ __/ _ \ '__/ __|
| | | (_| | | | (_| | | | | | |  __/ ||  __/ |  \__ \
\_|  \__,_|_|  \__,_|_| |_| |_|\___|\__\___|_|  |___/

*/                                                    
                                                     

    // setup root for the merkle tree
    bytes32 public root;
    
    // setup admin of the contract
    mapping (address => bool) public isAdmin;

    // informations of an address
    struct DataAddress {
        mapping (uint256 => uint256) consumption; // consumption's historic
        uint256 addressBalance; // Digital Euro balance in the contract
        uint256 amountToPay; // amount to pay to the Energy Provider
        uint256 totalDebt; // debt amount if missed payements
        uint256 totalNumberConsumption; // number of period of consumption
    }
    
    // setup msg.sender = identifiant
    mapping (address => DataAddress) public dataAddress;

    // setup timestamp's historic
    mapping (uint256 => uint256) public timestamp;
    uint256 totalTimestamp;

    // setup price's historic
    mapping (uint256 => uint256) public priceKW;
    uint256 totalPriceKW;

    // utils
    mapping (uint256 => address) public addressInSmartcontract;
    uint public totalAddresinSmartcontract;

    // setup Energy Provider to be paid
    address public EnergyProvider = payable(0x5217B68e37f5e4E860DC8Fa59026Ee31D19eb52A);

    // setup interface ERC20
    IERC20 private DigitalEuro = IERC20(0x8e5c6F50bCaBc51A8Ce502506bfE040475060500);


/*
 _   _ _                   
| | | (_)                  
| | | |_  _____      _____ 
| | | | |/ _ \ \ /\ / / __|
\ \_/ / |  __/\ V  V /\__ \
 \___/|_|\___| \_/\_/ |___/
                           
*/                           

    // check the total amount paid
    function checkTotalAmountPaid() public view returns (uint256) {
        uint totalAmountToPaidToTheCompany;
        address addressPayer;
        
        // get the historic of the amount due for all address stored in the contract
        for (uint i = 0; i < totalAddresinSmartcontract; i++) { 
            addressPayer = addressInSmartcontract[i];
            uint256 _amountToPay = dataAddress[addressPayer].amountToPay;
            totalAmountToPaidToTheCompany += _amountToPay;
        }   

        return totalAmountToPaidToTheCompany;
    }


    // check total consumption
    function checkTotalEnergyConsumed() public view returns (uint256) {
        uint totalAmountConsumed;
        address addressPayer;
        
        // get all address stored in the contract
        for (uint i = 0; i < totalAddresinSmartcontract; i++) { 
            addressPayer = addressInSmartcontract[i];
            
            // add to the total consumption from an address
            for (uint j = 0; i < dataAddress[addressPayer].totalNumberConsumption; i++) { 
                totalAmountConsumed += dataAddress[addressPayer].consumption[j];
            }
        }   

        return totalAmountConsumed;
    }


    // check the total consumption of an address
    function checkTotalConsumption(address _address) public view returns (uint256[] memory) {
        
        uint256[] memory ret = new uint256[](dataAddress[_address].totalNumberConsumption);

        // loop to get the historic of the mapping
        for (uint i = 0; i < dataAddress[_address].totalNumberConsumption; i++) { 
            ret[i] = dataAddress[_address].consumption[i];
        }
        
        return ret;    
    }


    // check the timestamp's historic
    function checkTimestamp() public view returns (uint256[] memory) {

        uint256[] memory ret = new uint256[](totalTimestamp);
        
        // loop to get the historic of the mapping
        for (uint i = 0; i < totalTimestamp; i++) { 
            ret[i] = timestamp[i];
        }

        return ret;
    } 


    // check the price's historic
    function checkPricKW() public view returns (uint256[] memory) {

        uint256[] memory ret = new uint256[](totalPriceKW);
        
        // loop to get the historic of the mapping
        for (uint i = 0; i < totalPriceKW; i++) { 
            ret[i] = priceKW[i];
        }

        return ret;
    } 


    // get the total amount to pay and the total consumption of an address for a specific period
    // _inputDay = start of the periode to check
    // _dayNumber = number of days to check
    function getPeriodConsumption(address _address, uint _inputDay, uint _dayNumber) public view returns (uint256, uint256) {
        
        // setup variables for the loop
        uint256 _TimestampStart = (_inputDay * 24) - 1;
        uint256 totalAmountToPayForThePeriod;
        uint256 totalConsumptionForThePeriod;
        uint256 _amountToPay;
        uint256 _consumption;

        // normalize the period depending on the collection period of the box in relation to the timestamp day 0 of the project
        uint256 _normalize = _TimestampStart-dataAddress[_address].totalNumberConsumption;
        
        // loop to get the historic of the address
        for (uint i = _TimestampStart; i < (_TimestampStart + 24) * _dayNumber; i++) { 
            _amountToPay = priceKW[i + _normalize] * dataAddress[_address].consumption[i];
            totalAmountToPayForThePeriod += _amountToPay;
            _consumption = dataAddress[_address].consumption[i];
            totalConsumptionForThePeriod += _consumption;
        }
        
        return (totalAmountToPayForThePeriod, totalConsumptionForThePeriod);
    }  


    // check if the address is included in the merkle proof
    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }


/*
______                _   _                    __                  _ _   _                   
|  ___|              | | (_)                  / _|                (_) | (_)                  
| |_ _   _ _ __   ___| |_ _  ___  _ __  ___  | |_ ___  _ __    ___ _| |_ _ _______ _ __  ___ 
|  _| | | | '_ \ / __| __| |/ _ \| '_ \/ __| |  _/ _ \| '__|  / __| | __| |_  / _ \ '_ \/ __|
| | | |_| | | | | (__| |_| | (_) | | | \__ \ | || (_) | |    | (__| | |_| |/ /  __/ | | \__ \
\_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/ |_| \___/|_|     \___|_|\__|_/___\___|_| |_|___/
                                                                                                                                                                                                                                     
*/                                           

    // to add a new consumption of an address, pondarate with a prime/malus
    function addNewConsumption(bytes32[] memory proof, uint256 _dataKW, uint256 _prime) public returns (bool){
        
        // to assure that the sender is the owner of the leaf
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not allowed"); 
        
        // add the address in the mapping if first time consumption
        if (dataAddress[msg.sender].amountToPay == 0){
            addressInSmartcontract[totalAddresinSmartcontract] = msg.sender;
            totalAddresinSmartcontract ++;
        }

        // launch the internal transaction to update the consumption
        _addConsumption(_dataKW, _prime);
        return true;
    }  


    // internal transaction to update the consumption
    function _addConsumption(uint256 _dataKW, uint256 _prime) internal {
        
        // get the price of the current period
        uint256 _priceKW = priceKW[totalPriceKW - 1];

        // setup the the consumption for the current period
        dataAddress[msg.sender].consumption[dataAddress[msg.sender].totalNumberConsumption] = _dataKW;
        dataAddress[msg.sender].totalNumberConsumption ++;
        
        // setup the amount to pay for the current period
        uint256 _amountToAdd = _dataKW * _priceKW * _prime;
        dataAddress[msg.sender].amountToPay += _amountToAdd;
    } 


    // recharge the balance with Digital Euro of the address to the contract
    function addBalance(uint256 _amount) external returns (bool) { 
        
        // check allowance, the contract must have access to the amount of Digital Euro in order to transfer
        uint256 allowance = DigitalEuro.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        
        // transfer Digital Euro to the contract and update the balance
        // /100 because Digital Euro has 2 digits
        dataAddress[msg.sender].addressBalance += _amount / 100; 
        return DigitalEuro.transferFrom(msg.sender, address(this), _amount);
        
    }


    // withdraw from the contract the Digital Euro balance of the address
    function withdrawBalance(uint256 _amount) external returns (bool) {
        
        // check if enough balance
        require(dataAddress[msg.sender].addressBalance >= _amount / 100, "Check the token balance"); // /100 because Digital Euro has 2 digits
        
        // update the balance and send the Digital Euro to the address
        dataAddress[msg.sender].addressBalance -= _amount / 100; // /100 because Digital Euro has 2 digits
        return DigitalEuro.transferFrom(address(this), msg.sender, _amount);

    }


    // repay the debt of the address
    function payDebt(bytes32[] memory proof, uint256 _amount) public returns (bool) {
        
        // to assure that the sender is the owner of the leaf
        require (isValid(proof, keccak256(abi.encodePacked(msg.sender))) || isAdmin[msg.sender] == true); 

        // to assure that the address has enough balance
        require (dataAddress[msg.sender].addressBalance >= _amount / 100); // /100 because Digital Euro has 2 digits
        
        // update the debt and transfer to the Energy Provider
        dataAddress[msg.sender].totalDebt -= _amount / 100;
        return DigitalEuro.transferFrom(address(this), EnergyProvider, _amount);
    }

/*
______                _   _                    __             _____                            ______               _     _           
|  ___|              | | (_)                  / _|           |  ___|                           | ___ \             (_)   | |          
| |_ _   _ _ __   ___| |_ _  ___  _ __  ___  | |_ ___  _ __  | |__ _ __   ___ _ __ __ _ _   _  | |_/ / __ _____   ___  __| | ___ _ __ 
|  _| | | | '_ \ / __| __| |/ _ \| '_ \/ __| |  _/ _ \| '__| |  __| '_ \ / _ \ '__/ _` | | | | |  __/ '__/ _ \ \ / / |/ _` |/ _ \ '__|
| | | |_| | | | | (__| |_| | (_) | | | \__ \ | || (_) | |    | |__| | | |  __/ | | (_| | |_| | | |  | | | (_) \ V /| | (_| |  __/ |   
\_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/ |_| \___/|_|    \____/_| |_|\___|_|  \__, |\__, | \_|  |_|  \___/ \_/ |_|\__,_|\___|_|   
                                                                                   __/ | __/ |                                        
                                                                                  |___/ |___/                                         
*/

    // to update the Energy Provider
    function changeEnergyProvider(address _newProvider) public returns (bool) {
        
        // require msg.sender is the actual energy provider or and admin of the contract
        require(EnergyProvider == msg.sender || isAdmin[msg.sender] == true);
        
        // update the Energy Provider
        EnergyProvider = payable(_newProvider);
        return true;
    }


    // to add a new price for the next timestamp
    function addNewPrice(uint256 _dataTimestamp, uint256 _priceKW) public returns (bool){
        
        // only the Energy Provider can add a price
        require(msg.sender == EnergyProvider);
        
        // update the timestamp and price
        timestamp[totalTimestamp] = _dataTimestamp;
        totalTimestamp ++;
        priceKW[totalPriceKW] = _priceKW;
        totalPriceKW ++;
        return true;
    } 


    // get paid
    function payEnergyCompany() external payable returns (bool) {
        
        // only the Energy Provider can launch the function
        require(msg.sender == EnergyProvider);
        
        // parameters for the loop
        uint totalAmountToPayToTheCompany;
        address addressPayer;
        
        // get the historic of the amount due for all address stored in the contract
        for (uint i = 0; i < totalAddresinSmartcontract; i++) { 
            addressPayer = addressInSmartcontract[i];
            uint256 _amountToPay = dataAddress[addressPayer].amountToPay;

            // the address has enough balance in the contract to pay
            if (dataAddress[addressPayer].addressBalance >= _amountToPay) { 
                totalAmountToPayToTheCompany += _amountToPay;
                
                // update the balance and amount to pay of the address
                dataAddress[addressPayer].amountToPay -= _amountToPay;
                dataAddress[addressPayer].addressBalance -= _amountToPay;
            
            // the address has not enough balance to pay
            } else {

                // add debt for the address
                dataAddress[addressPayer].totalDebt += _amountToPay;
            }
        }

        // transfer the totalAmountToPayToTheCompany from the contract to the Energy Provider
        return DigitalEuro.transferFrom(address(this), EnergyProvider, totalAmountToPayToTheCompany * 100); // *100 because Digital Euro has 2 digits
    }

/*
  ___      _           _            ______                _   _                  
 / _ \    | |         (_)           |  ___|              | | (_)                 
/ /_\ \ __| |_ __ ___  _ _ __  ___  | |_ _   _ _ __   ___| |_ _  ___  _ __  ___  
|  _  |/ _` | '_ ` _ \| | '_ \/ __| |  _| | | | '_ \ / __| __| |/ _ \| '_ \/ __| 
| | | | (_| | | | | | | | | | \__ \ | | | |_| | | | | (__| |_| | (_) | | | \__ \ 
\_| |_/\__,_|_| |_| |_|_|_| |_|___/ \_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/ 
                                                                                 
*/                                                                                

    // to add a new admin
    function addAdmin(address _newAdmin) public onlyOwner returns (bool){ 
        isAdmin[_newAdmin] = true;
        return true;
    }

    // to remove an admin
    function removeAdmin(address _Admin) public onlyOwner returns (bool){ 
        isAdmin[_Admin] = false;
        return true;
    }

    // to change the root of the merkle tree
    // only by owner
    function changeRoot(bytes32 _newRoot) public onlyOwner returns (bool) { 
        
        // update the root
        root = _newRoot;
        return true;
    }  

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}