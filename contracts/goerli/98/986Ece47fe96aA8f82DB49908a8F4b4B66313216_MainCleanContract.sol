// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract MainCleanContract {
    // total number of contract
    uint256 public ccCounter;

    // houseNFT contract address
    address public houseNFTAddress;

    // define contract struct
    struct CleanContract {
        uint256 contractId;
        string companyName;
        string contractType;
        string contractURI;
        uint256 dateFrom;
        uint256 dateTo;
        uint256 agreedPrice;
        string currency;
        address creator;
        address owner;
        bool creatorApproval;
        uint256 creatorSignDate;
        address contractSigner;
        bool signerApproval;
        uint256 signerSignDate;
        string status;
    }

    // define notification 6
    struct Notify {
        address nSender;
        address nReceiver;
        uint256 ccID;
        uint256 notifySentTime;
        string notifyContent;
        bool status;
    }

    // map house's token id to house
    mapping(uint256 => CleanContract) allCleanContracts;
    // map contracts of owner
    mapping(address => uint256[]) allContractsByOwner;
    // map contracts of signer
    mapping(address => uint256[]) allContractsBySigner;
    // notifications
    mapping(address => Notify[]) allNotifies;

    constructor(address addr) {
        houseNFTAddress = addr;
    }

    // write Contract
    function ccCreation(
        string memory _companyName,
        string memory _contractType,
        address _contractSigner,
        string memory _contractURI,
        uint256 _dateFrom,
        uint256 _dateTo,
        uint256 _agreedPrice,
        string memory _currency
    ) public {
        ccCounter++;
        CleanContract storage singleContract = allCleanContracts[ccCounter];
        singleContract.contractId = ccCounter;
        singleContract.contractURI = _contractURI;
        singleContract.companyName = _companyName;
        singleContract.contractType = _contractType;
        singleContract.dateFrom = _dateFrom;
        singleContract.dateTo = _dateTo;
        singleContract.agreedPrice = _agreedPrice;
        singleContract.currency = _currency;
        singleContract.status = 'pending';
        singleContract.owner = msg.sender;
        singleContract.creator = msg.sender;
        singleContract.contractSigner = _contractSigner;
        require(singleContract.creator != _contractSigner, "Owner can't be signer");
        if (_contractSigner != address(0)) {
            bool flag = false;
            // allContractsBySigner
            uint256[] storage allCons = allContractsBySigner[_contractSigner];
            for (uint256 i = 0; i < allCons.length; i++) {
                if (allCons[i] == ccCounter) {
                    flag = true;
                }
            }
            if (flag == false) {
                allCons.push(ccCounter);
            }
        }
        singleContract.creatorApproval = false;
        singleContract.signerApproval = false;

        uint256[] storage contractsByOwner = allContractsByOwner[msg.sender];
        contractsByOwner.push(ccCounter);
    }

    // Get All Contracts
    function getAllContractsByOwner() public view returns (CleanContract[] memory) {
        uint256[] memory contractsByOwner = allContractsByOwner[msg.sender];
        CleanContract[] memory contracts = new CleanContract[](contractsByOwner.length);
        for (uint256 i = 0; i < contractsByOwner.length; i++) {
            contracts[i] = allCleanContracts[contractsByOwner[i]];
        }
        return contracts;
    }

    // Get All Signer Contracts
    function getAllContractsBySigner() public view returns (CleanContract[] memory) {
        uint256[] memory allCons = allContractsBySigner[msg.sender];
        CleanContract[] memory contracts = new CleanContract[](allCons.length);
        for (uint256 i = 0; i < allCons.length; i++) {
            contracts[i++] = allCleanContracts[allCons[i]];
        }
        return contracts;
    }

    // Add Contract Signer
    function addContractSigner(uint256 _ccID, address _contractSigner) public {
        CleanContract storage singleContract = allCleanContracts[_ccID];
        require(singleContract.creator == msg.sender, 'Only contract creator can add contract signer');
        require(singleContract.creator != _contractSigner, "Owner can't be signer");
        singleContract.contractSigner = _contractSigner;
        bool flag = false;
        // allContractsBySigner
        uint256[] storage allCons = allContractsBySigner[_contractSigner];
        for (uint256 i = 0; i < allCons.length; i++) {
            if (allCons[i] == _ccID) {
                flag = true;
            }
        }
        if (flag == false) {
            allCons.push(_ccID);
        }
    }

    // sign contract
    function signContract(uint256 ccID) public {
        CleanContract storage singleContract = allCleanContracts[ccID];
        require(
            msg.sender == singleContract.creator || msg.sender == singleContract.contractSigner,
            "You don't have permission to this contract"
        );
        uint256 flag = 0;
        if (msg.sender == singleContract.creator) {
            singleContract.creatorApproval = true;
            if (singleContract.signerApproval == true) {
                singleContract.status = 'signed';
                singleContract.creatorSignDate = block.timestamp;
                flag = 1;
            }
        } else if (msg.sender == singleContract.contractSigner) {
            singleContract.signerApproval = true;
            if (singleContract.creatorApproval == true) {
                singleContract.status = 'signed';
                singleContract.signerSignDate = block.timestamp;
                flag = 2;
            }
        }
        if (flag == 1) {
            for (uint256 i = 0; i < allNotifies[singleContract.creator].length; i++) {
                if (allNotifies[singleContract.creator][i].ccID == ccID) {
                    allNotifies[singleContract.creator][i].status = true;
                }
            }
        } else if (flag == 2) {
            for (uint256 i = 0; i < allNotifies[singleContract.contractSigner].length; i++) {
                if (allNotifies[singleContract.contractSigner][i].ccID == ccID) {
                    allNotifies[singleContract.contractSigner][i].status = true;
                }
            }
        } else {
            address _notifyReceiver;
            if (msg.sender == singleContract.creator) {
                _notifyReceiver = singleContract.contractSigner;
            } else {
                _notifyReceiver = singleContract.creator;
            }

            string memory stringAddress = addressToString(msg.sender);
            string memory notifyMsg = append('New signing request from ', stringAddress);

            Notify memory newNotify = Notify({
                nSender: msg.sender,
                nReceiver: _notifyReceiver,
                ccID: ccID,
                notifySentTime: 0,
                notifyContent: notifyMsg,
                status: false
            });
            allNotifies[_notifyReceiver].push(newNotify);
        }
    }

    // send sign notification
    function sendNotify(
        address _notifyReceiver,
        string memory _notifyContent,
        uint256 ccID
    ) external {
        CleanContract storage cContract = allCleanContracts[ccID];
        require(cContract.contractSigner != address(0), 'Please add contract signer.');
        Notify[] storage notifies = allNotifies[cContract.contractSigner];
        if (notifies.length > 0) {
            require(
                notifies[notifies.length - 1].notifySentTime + 24 * 3600 <= block.timestamp,
                'You can send notify once per day.'
            );
        }
        Notify memory newNotify = Notify({
            nSender: msg.sender,
            nReceiver: _notifyReceiver,
            ccID: ccID,
            notifySentTime: block.timestamp,
            notifyContent: _notifyContent,
            status: false
        });
        allNotifies[_notifyReceiver].push(newNotify);
    }

    function getUploadedCounter() public view returns (uint256) {
        return ccCounter;
    }

    // get my all notifies
    function getAllNotifies() public view returns (Notify[] memory) {
        return allNotifies[msg.sender];
    }

    // Devide number
    function calcDiv(uint256 a, uint256 b) external pure returns (uint256) {
        return (a - (a % b)) / b;
    }

    // declare this function for use in the following 3 functions
    function toString(bytes memory data) public pure returns (string memory) {
        bytes memory alphabet = '0123456789abcdef';

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    // cast address to string
    function addressToString(address account) public pure returns (string memory) {
        return toString(abi.encodePacked(account));
    }

    // cast uint to string
    function uintToString(uint256 value) public pure returns (string memory) {
        return toString(abi.encodePacked(value));
    }

    // cast bytes32 to string
    function bytesToString(bytes32 value) public pure returns (string memory) {
        return toString(abi.encodePacked(value));
    }

    function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    /**
     * @dev modifies ownership of `contractId` from `from` to `to`
     */
    function transferContractOwnership(
        uint256 contractId,
        address from,
        address to
    ) external {
        require(msg.sender == houseNFTAddress, 'only house contract');

        uint256[] memory contracts = allContractsByOwner[from];
        uint256 length = contracts.length;

        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                if (contractId == contracts[i]) {
                    allContractsByOwner[from][i] = allContractsByOwner[from][length - 1];
                    allContractsByOwner[from].pop();
                    break;
                }
            }
        }

        allContractsByOwner[to].push(contractId);
        allCleanContracts[contractId].owner = to;
    }
}