/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

pragma solidity ^0.8.0;

//assumes that any string argument in a function is already properly formatted (ex. labelName)

contract LabelContract {
    // Each asset item will map to one of these
    struct LabelData {
        uint256 labelValues; //Ex: 0101001010 gets converted into whether each label is "on" or "off"
        string[] proofs; //array of pointers to storage of proofs
    }

    mapping(string => uint256) public labelIndices; // pairing of label name -> index storage of each label

    mapping(address => LabelData) private labelInfo; // pairing of NFT address -> Label struct
    string[] private allLabels; // array storage of label - order corresponding to position of the label
    address private owner;
    mapping(address => bool) public whiteListedAuditors;

    event NewLabelAdded(string labelName, uint256 labelIndex);

    event FilterFactoryCreated(address filterFactoryAddress);

    event NewAuditedAsset(address asset);

    constructor() {
        owner = msg.sender;
        FilterFactory ff = new FilterFactory(address(this));
        emit FilterFactoryCreated(address(ff));
    }

    function auditedLabels(address asset)
        external
        view
        returns (uint256 audited)
    {
        audited = 0;
        for (uint256 i = 0; i < labelInfo[asset].proofs.length; i++) {
            if (bytes(labelInfo[asset].proofs[i]).length > 0) {
                //this label is audited.
                audited |= (1 << i);
            }
        }
    }

    function getAllLabels() external view returns (string[] memory) {
        return allLabels;
    }

    function addWhitelistAuditor(address newAuditor) public {
        require(
            owner == msg.sender,
            "ONLY CONTRACT OWNER CAN ADD NEW AUDITORS"
        );
        whiteListedAuditors[newAuditor] = true;
    }

    function getLabelOfAsset(address asset, uint256 labelIndex)
        public
        view
        returns (bool)
    {
        require(labelIndex < allLabels.length, "Label index does not exist.");
        uint256 labelData = getLabelData(asset);
        return ((labelData >> labelIndex) & 1) != 0; //gets nth bit, where n is labelIndex
    }

    function getLabelOfAsset(address asset, string calldata labelName)
        external
        view
        returns (bool)
    {
        require(labelExists(labelName), "No such label name exists.");
        uint256 index = labelIndices[labelName];
        return getLabelOfAsset(asset, index);
    }

    //_address is of the nft collection
    function getLabelData(address asset) public view returns (uint256) {
        uint256 retVal = labelInfo[asset].labelValues;
        return retVal; // Defaults to a LabelData with no real value (or proofs)
    }

    function getProofs(address asset) external view returns (string[] memory) {
        return labelInfo[asset].proofs;
    }

    function labelExists(string calldata _label) public view returns (bool) {
        //label is not the first one (but exists), or label is the first one
        return
            labelIndices[_label] > 0 ||
            (allLabels.length > 0 &&
                keccak256(abi.encode(allLabels[0])) ==
                keccak256(abi.encode(_label)));
    }

    //creates original Label
    function addLabel(string calldata _newLabel) public {
        require(!labelExists(_newLabel), "Label already exists."); // requires that the label doesn't exist
        require(
            whiteListedAuditors[msg.sender],
            "Auditor/contributor not whitelisted."
        );
        // Append
        uint256 newIndex = allLabels.length;
        labelIndices[_newLabel] = newIndex;
        allLabels.push(_newLabel);
        emit NewLabelAdded(_newLabel, newIndex);
    }

    function changeLabelValue(
        address asset,
        string calldata _label,
        bool _labelValue,
        string calldata _labelProof
    ) private {
        require(bytes(_labelProof).length > 0, "Proof cannot be empty.");
        if (!labelExists(_label)) {
            addLabel(_label);
        }
        uint256 index = labelIndices[_label];

        //add/edit labelValue
        if (_labelValue) {
            //change to 1
            labelInfo[asset].labelValues |= 1 << index;
        } else {
            //change to 0
            labelInfo[asset].labelValues &= ~(1 << index); //& with a uint256 of all 1s except at the index.
        }

        if (labelInfo[asset].proofs.length == 0) {
            emit NewAuditedAsset(asset);
        }

        //make sure proofs array can accommodate if it's a new label
        while (index >= labelInfo[asset].proofs.length) {
            labelInfo[asset].proofs.push("");
        }
        //add/edit labelProof (overrides previous value)
        labelInfo[asset].proofs[index] = _labelProof;
    }

    //add/edit label to NFT collection : needs address, String label, uint256 label value, string proof
    function editLabelData(
        address asset,
        string calldata _label,
        bool _labelValue,
        string calldata _labelProof
    ) public {
        require(
            whiteListedAuditors[msg.sender],
            "Auditor/contributor not whitelisted."
        );
        changeLabelValue(asset, _label, _labelValue, _labelProof);
    }

    //labelsToChange, newValues, and proofs must all be in the same order (index i of each refers to the same audit)
    function editMultipleLabelsForAsset(
        address asset,
        string[] calldata labelsToChange,
        bool[] calldata newValues,
        string[] calldata proofs
    ) external {
        require(
            whiteListedAuditors[msg.sender],
            "Auditor/contributor not whitelisted."
        );
        require(
            labelsToChange.length == newValues.length,
            "LabelsToChange parameter array must be same length as newValues parameter array."
        );
        require(
            proofs.length == newValues.length,
            "Proofs parameter array must be same length as newValues parameter array."
        );

        for (uint256 i = 0; i < labelsToChange.length; i++) {
            changeLabelValue(asset, labelsToChange[i], newValues[i], proofs[i]);
        }
    }

    //assets, newValues, and proofs must all be in the same order (index i of each refers to the same audit)
    function editLabelForMultipleAssets(
        string calldata labelName,
        address[] calldata assets,
        bool[] calldata newValues,
        string[] calldata proofs
    ) external {
        require(
            whiteListedAuditors[msg.sender],
            "Auditor/contributor not whitelisted."
        );
        require(
            assets.length == newValues.length,
            "assets parameter array must be same length as newValues parameter array."
        );
        require(
            proofs.length == newValues.length,
            "Proofs parameter array must be same length as newValues parameter array."
        );

        for (uint256 i = 0; i < assets.length; i++) {
            changeLabelValue(assets[i], labelName, newValues[i], proofs[i]);
        }
    }

    function getProof(address asset, string calldata _label)
        public
        view
        returns (string memory)
    {
        require(labelExists(_label), "Label requested does not exist.");
        uint256 labelIndex = labelIndices[_label];
        require(
            labelIndex < labelInfo[asset].proofs.length,
            "Label data does not exist."
        );
        string memory proof = labelInfo[asset].proofs[labelIndex];
        require(bytes(proof).length > 0, "Proof does not exist.");
        return proof;
    }
}

contract FilterFactory {
    mapping(uint256 => mapping(uint256 => address)) public getFilterAddress; //pairing of filtermap -> filtercontract address
    address public labelContract;
    address[] public allFilters;

    event FilterCreated(
        uint256 labelsRequired,
        uint256 valuesRequired,
        address newFilter,
        uint256
    );

    constructor(address labelContractAddress) {
        labelContract = address(labelContractAddress);
    }

    function getAllFilters() external view returns (address[] memory filters) {
        filters = allFilters;
    }

    function createFilter(
        uint256 labelsRequired,
        uint256 valuesRequired,
        string calldata name
    ) external returns (address newFilterAddress) {
        require(
            getFilterAddress[labelsRequired][valuesRequired] == address(0),
            "FILTER ALREADY EXISTS."
        );
        HonestFilter newFilter = new HonestFilter();
        newFilter.initialize(
            labelsRequired,
            valuesRequired,
            name,
            labelContract
        );
        newFilterAddress = address(newFilter);
        getFilterAddress[labelsRequired][valuesRequired] = newFilterAddress;
        allFilters.push(newFilterAddress);
        emit FilterCreated(
            labelsRequired,
            valuesRequired,
            newFilterAddress,
            allFilters.length
        );
    }

    function getMissedCriteria(
        address asset,
        uint256 labelsRequired,
        uint256 valuesRequired
    ) external view returns (uint256 misses) {
        address filter = getFilterAddress[labelsRequired][valuesRequired];
        require(filter != address(0), "FILTER DOES NOT EXIST.");
        misses = HonestFilter(filter).getMissedCriteria(asset);
    }
}

contract HonestFilter {
    address public factory;
    uint256 public labelsRequired;
    uint256 public valuesRequired;
    address private labelContract;
    string public name;

    constructor() {
        factory = msg.sender; //to check later if the msg sender is valid
        require(factory != address(0), "FACTORY DOES NOT EXIST.");
    }

    function isValidRequirement(uint256 mask, uint256 numLabels)
        private
        pure
        returns (bool)
    {
        uint256 labelsUsed;
        for (labelsUsed = 0; mask > 0; mask >>= 1) labelsUsed += 1;
        return labelsUsed <= numLabels;
    }

    function valueReqsFitLabelReqs(
        uint256 _labelsRequired,
        uint256 _valuesRequired
    ) private pure returns (bool) {
        for (
            uint256 i = 1;
            i <= _labelsRequired && i <= _valuesRequired;
            i <<= 1
        ) {
            if (
                (i & _valuesRequired != 0) && (i & _labelsRequired == 0) // valueRequired is 1 for that label
            ) {
                //labelRequired is 0 for that label
                return false;
            }
        }
        return true;
    }

    //  Called by the factory at time of deployment
    function initialize(
        uint256 _labelsRequired,
        uint256 _valuesRequired,
        string calldata _name,
        address _labelContract
    ) external {
        require(msg.sender == factory, "FORBIDDEN");
        uint256 allLabels = LabelContract(_labelContract).getAllLabels().length;
        require(
            isValidRequirement(_labelsRequired, allLabels),
            "labelsRequired must use existing labels"
        );
        require(
            isValidRequirement(_valuesRequired, allLabels),
            "valuesRequired must use existing labels"
        );
        require(
            valueReqsFitLabelReqs(_labelsRequired, _valuesRequired),
            "can only require a TRUE for a required label"
        );
        labelsRequired = _labelsRequired;
        valuesRequired = _valuesRequired;
        labelContract = _labelContract;
        name = _name;
    }

    //if it passes the filter, this will return 0.
    function getMissedCriteria(address assetAddress)
        public
        view
        returns (uint256)
    {
        uint256 labelData = LabelContract(labelContract).getLabelData(
            assetAddress
        );
        uint256 rawDataFilterDiff = labelData ^ valuesRequired; // all differences, including nonrequired values
        return rawDataFilterDiff & labelsRequired;
    }

    function assetPassesFilter(address assetAddress)
        external
        view
        returns (bool)
    {
        return getMissedCriteria(assetAddress) == 0;
    }
}