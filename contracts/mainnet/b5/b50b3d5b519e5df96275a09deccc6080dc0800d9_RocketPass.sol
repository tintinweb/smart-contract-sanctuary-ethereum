/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

error CallerNotOwner();
error NewOwnerAddressZero();

abstract contract ERC1155SingleTokenPausable {

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 amount);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    mapping(address => mapping(uint256 => uint256)) private _balanceOf;
    mapping(address => mapping(address => bool)) private _isApprovedForAll;

    string public name;
    string public symbol;
    address public owner;
    bool public isPaused;

    constructor (string memory _name, string memory _symbol){
        name = _name;
        symbol = _symbol;
        _transferOwnership(msg.sender);
    }

    function uri(uint256 id) public view virtual returns (string memory);

    function balanceOf(address _address, uint256 id) public view returns (uint256) {
        return _balanceOf[_address][id];
    }
    
    function isApprovedForAll(address _owner, address operator) public view returns (bool) {
        return  _isApprovedForAll[_owner][operator];
    }

    function setApprovalForAll(address operator, bool approved) public {
        _isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 id, uint256 amount) public {
        require(!isPaused, "RocketPass is currently locked.");
        require(msg.sender == from || _isApprovedForAll[from][msg.sender], "Lacks Permissions");

        _balanceOf[from][id] -= amount;
        _balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, 1, amount);
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) public {
        transferFrom(from, to, id, amount);
        require(to.code.length == 0 ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "Unsafe Destination"
        );
    }

    function _mint(address to, uint256 amount) internal {
        _balanceOf[to][1] += amount;
        emit TransferSingle(msg.sender, address(0), to, 1, amount);
    }

    function _safeMint(address to, uint256 amount, bytes memory data) internal {
        _mint(to, amount);
        require(to.code.length == 0 ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), 1, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "Unsafe Destination"
        );
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 ||
            interfaceId == 0xd9b67a26 ||
            interfaceId == 0x0e89341c;
    }

    function flipPauseState() external onlyOwner {
        if (isPaused){
            delete isPaused; 
        } else {
            isPaused = true;
        }
    }

    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) revert NewOwnerAddressZero();
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    modifier onlyOwner() {
        if (owner != msg.sender) revert CallerNotOwner();
        _;
    }

}

abstract contract ERC1155TokenReceiver {
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

}

interface IOGMiner {
    function balanceOf(address owner) external view returns (uint256);
}

interface IHASH{
    function balanceOf(address account) external view returns (uint256);
    function burnHash(uint256 _amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract RocketPass is ERC1155SingleTokenPausable {

    uint256 public constant hashPrice = 600 ether;
    uint256 public constant ethOGPrice = .05 ether;
    uint256 public constant ethRLPrice = .069 ether;

    uint256 public stateHashMint;
    uint256 public stateEthMint;

    bytes32 public RLMerkleRoot;
    string public passURI = "ipfs://QmbtHrneD8JnBtS5YFPfjaiXKexhs3DkYzP3SKg9ypqpVY";
    bool public permanentlyClosedMint;

    IOGMiner public og;
    IHASH public hashpower;

    mapping(address => uint256) public OGMints;
    mapping(address => uint256) public RLMints;

    constructor(address _hContract, address _ogContract) ERC1155SingleTokenPausable("BMC Rocket Pass", "RKTPASS"){
        og = IOGMiner(_ogContract);
        hashpower = IHASH(_hContract);
        _mint(msg.sender, 100);
    }

    modifier onlyHuman() {
        require(tx.origin == msg.sender && msg.sender.code.length == 0, "No Contracts");
        _;
    }

    function mintWithHash(uint256 _amount) external onlyHuman {
        require(stateHashMint > 0, "Sale Closed");
        uint256 hashToBurn = hashPrice*_amount;
        require(hashpower.balanceOf(msg.sender)>=hashToBurn, "Not enough Hash Owned");
        require(hashpower.allowance(msg.sender, address(this)) >= hashToBurn, "Insufficient allowed hash");

        hashpower.transferFrom(msg.sender, address(this), hashToBurn);
        _mint(msg.sender, _amount);
    }

    function mintWithOG(uint256 _amount) external payable onlyHuman {
        require(stateEthMint > 0, "Sale Closed");
        require(og.balanceOf(msg.sender) - OGMints[msg.sender] > 0, "No Remaining OG Mints");
        uint256 costEth = ethOGPrice * _amount;

        require(msg.value >= costEth, "Not enough Eth attached");
        unchecked { // Cannot overflow since we checked they have sufficient OG balance and ETH
            OGMints[msg.sender] += _amount;
        }
        _mint(msg.sender, _amount);

    }

    function mintRL(bytes32[] calldata _proof) external payable onlyHuman {
        require(stateEthMint > 0, "Sale Closed");
        require(verifyRL(_proof, RLMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not on ML");
        require(RLMints[msg.sender] == 0, "Already ML Minted");
        require(msg.value >= ethRLPrice, "Not enough Eth attached");

        RLMints[msg.sender]++;
        _mint(msg.sender, 1);
    }

    function setState(uint256 _category, uint256 _value) external onlyOwner {
        bool adjusted;
        require(!permanentlyClosedMint, "Mint states permanently locked");
        if (_category == 0){
            stateHashMint = _value;
            adjusted = true;
        }

        if (_category == 1){
            stateEthMint = _value;
            adjusted = true;
        }
        require(adjusted, "Incorrect parameters");
    }

    function permanentlyCloseMint() external onlyOwner {
        require(!permanentlyClosedMint, "Already permanently locked");
        delete stateHashMint;
        delete stateEthMint;
        permanentlyClosedMint = true;
    }

    function BurnTheHash() external onlyOwner {
        hashpower.burnHash(hashpower.balanceOf(address(this)));
    }

    function setURI(string calldata _newURI) external onlyOwner {
        passURI = _newURI;
        emit URI(_newURI, 1);
    }

    function setRoot(bytes32 _newROOT) external onlyOwner {
        RLMerkleRoot = _newROOT;
    }

    function setHASHPOWER(address _address) external onlyOwner {
        hashpower = IHASH(_address);
    }

    function setOG(address _address) external onlyOwner {
        og = IOGMiner(_address);
    }

    function verifyHashBalance(address _address) public view returns (bool){
        return (hashpower.balanceOf(_address) - hashPrice) > 0;
    }

    function verifyHashApproved(address _address) public view returns (bool){
        return hashpower.allowance(_address, address(this)) >= hashPrice;
    }
    
    function verifyOG(address _address) public view returns (bool){
        return (og.balanceOf(_address) - OGMints[_address]) > 0;
    }

    function verifyRL(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        uint256 iterations = proof.length;
        for (uint256 i; i < iterations; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash == root;
    }

    function uri(uint256 id) public view override returns (string memory){
        return passURI;
    }

    function withdrawFunding() external onlyOwner {
        uint256 currentBalance = address(this).balance;
        (bool sent, ) = address(msg.sender).call{value: currentBalance}('');
        require(sent,"Error while transferring balance");    
  }

}