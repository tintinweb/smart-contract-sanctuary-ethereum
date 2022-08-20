// SPDX-License-Identifier: MIT
/*

 ██████  ███████ ███    ██ ███████ ███████ ██ ███████      ██████  ██████  ███████ ███████ ███    ██ ███████     ██████   █████  ███████ ███████ 
██       ██      ████   ██ ██      ██      ██ ██          ██       ██   ██ ██      ██      ████   ██    ███      ██   ██ ██   ██ ██      ██      
██   ███ █████   ██ ██  ██ █████   ███████ ██ ███████     ██   ███ ██████  █████   █████   ██ ██  ██   ███       ██████  ███████ ███████ ███████ 
██    ██ ██      ██  ██ ██ ██           ██ ██      ██     ██    ██ ██   ██ ██      ██      ██  ██ ██  ███        ██      ██   ██      ██      ██ 
 ██████  ███████ ██   ████ ███████ ███████ ██ ███████      ██████  ██   ██ ███████ ███████ ██   ████ ███████     ██      ██   ██ ███████ ███████ 
                                                                                                                                                 
*/
pragma solidity ^0.8.9;

import "./Counters.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./AbstractERC1155Factory.sol";
import "./PaymentSplitter.sol";


contract GenesisGreenzPass is AbstractERC1155Factory, PaymentSplitter {

    uint256 public constant MAX_SUPPLY = 1130;
    uint256 public constant MAX_SUPPLY_WL = 710;
    uint256 public constant MAX_SUPPLY_FREE = 420;

    uint256 public maxMintAmountPerTx = 1;
    uint256 public mintPrice = 0.099 ether;
    bool public whitelistMintEnabled = false;
    bytes32 public wlMerkleRoot = 0x7cb4f9128a88d974b939532a99d455b1c572b2d821c17bd62513e0f8fba21a3a;
    bytes32 public freeMerkleRoot = 0x409fddf553947a31a0daf6de9e8df17d0fa2eb9d06be51b2d726a744c17e78e6;
    mapping(address => bool) public freelistClaimed;
    string public uriSuffix = '.json';  
    address[] _payees = [0xc80855d8b265523B143069d7f3977d06461CE463, 0x6b9EC7e1804735C788FD317d62B2f919e460d7c3, 0x3A5cD7B65F8B23DF37e269FAe8cA7764b3B9cE26, 0xdbD2088fc18552E157Ea87f3BC3A873140F7DD0B];
    uint256[] _shares = [80, 10, 5, 5];
    event Purchased(uint256 indexed index, address indexed account, uint256 amount);

    constructor() ERC1155("https://greenfarmfactory.mypinata.cloud/ipfs/Qma9oQvwwZganwYFkrsDZH6FdmbowyjrZa5serZBJheQS9/") PaymentSplitter(_payees, _shares) {
        name_ = "Genesis Greenz Pass";
        symbol_ = "GGP";
    }

    modifier mintCompliance(uint256 _mintAmount, uint256 _id) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
        validateMaxSupply(_mintAmount, _id);
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= mintPrice * _mintAmount, 'Insufficient funds!');
        _;
    }

    function validateMaxSupply(uint256 _mintAmount, uint256 _id) private view {
        uint256 _maxSupply;
        if (_id == 0) {
            _maxSupply = MAX_SUPPLY_WL;
        } else {
            _maxSupply = MAX_SUPPLY_FREE;
        }
        require(totalSupply(_id) + _mintAmount <= _maxSupply, 'Max supply exceeded!');
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public mintCompliance(_mintAmount, 0) mintPriceCompliance(_mintAmount) payable {
        require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, wlMerkleRoot, leaf), 'Invalid proof!');
        _safeMint(_msgSender(), _mintAmount, 0);
    }

    function freeMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public mintCompliance(_mintAmount, 1) payable {
        require(whitelistMintEnabled, 'The freelist sale is not enabled!');
        require(!freelistClaimed[_msgSender()], 'Address already claimed!');
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, freeMerkleRoot, leaf), 'Invalid proof!');
        _safeMint(_msgSender(), _mintAmount, 1);
        freelistClaimed[_msgSender()] = true;
    }

    function publicMint(uint256 _mintAmount) public mintCompliance(_mintAmount, 0) mintPriceCompliance(_mintAmount) whenNotPaused payable {
        _safeMint(_msgSender(), _mintAmount, 0);
    }

    function internalMint(uint256 _teamAmount, uint256 _id) public onlyOwner {
        validateMaxSupply(_teamAmount, _id);
        _safeMint(_msgSender(), _teamAmount, _id);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver, uint256 _id) public onlyOwner {
        validateMaxSupply(_mintAmount, _id);
        _safeMint(_receiver, _mintAmount, _id);
    }

    function mintForAddresses(uint256 _id, address[] memory _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            mintForAddress(1, _addresses[i], _id);
        }
    }

    function _safeMint(address to, uint256 _amount, uint256 _id) private {
        _mint(to, _id, _amount, "");
        emit Purchased(_id, to, _amount);
    }

    function release(address payable account) public override {
        require(msg.sender == account || msg.sender == owner(), "Release: no permission");
        super.release(account);
    }

    function tokenURI(uint256 _id) public view returns(string memory) {
        return uri(_id);
    }

    function uri(uint256 _id) public view override returns(string memory) {
        require(exists(_id), "URI: nonexistent token");
        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id), uriSuffix));
    }

    function setWlMerkleRoot(bytes32 _wlMerkleRoot) external onlyOwner {
        wlMerkleRoot = _wlMerkleRoot;
    }

    function setFreeMerkleRoot(bytes32 _freeMerkleRoot) external onlyOwner {
        freeMerkleRoot = _freeMerkleRoot;
    }

    function setPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxMintAmountPerTx(uint8 _maxMintAmountPerTx) external onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function withdrawAmountTo(uint256 amount, address payable to) public onlyOwner {
        uint256 _balance = address(this).balance ;
        require(_balance > 0, "withdraw amount call without balance");
        require(_balance-amount >= 0, "withdraw amount call with more than the balance");
        require(payable(to).send(amount), "FAILED withdraw amount call");
    }
}