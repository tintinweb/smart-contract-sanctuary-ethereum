// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./ERC1155Supply.sol";
import "./Ownable.sol";

contract Tickets is ERC1155Supply, Ownable {
    string public name;
    string public symbol;
    uint256 public ticket1Price = 0.07 ether;
    uint256 public ticket2Price = 0.15 ether;
    uint256 public ticket3Price = 0.15 ether;
    bool public paused = true;
    address Contract;

    mapping(uint256 => string) public tokenURI;

    constructor() ERC1155("") {
        name = "Glory Games Standard Presale NFT Pass";
        symbol = "$GLORYPREMINT";
        tokenURI[1] = "ipfs://QmVD6FLz5bZ5YuXYPRG8Do7WWG7RMePFagTHdCycpqtByE/";
        tokenURI[2] = "ipfs://QmRvJFYmYctofhdFcYMZcqRmQvh4cCn3aLzW3qv3t112Se/";
        tokenURI[3] = "ipfs://QmS25TSDqctmCazDPDJgM8hoNqVfARDXVqegNfxHu39YoL/";
        tokenURI[4] = "ipfs://QmY4yWTgcFqbXg7sVVHQdQj57E77wgoifvuc9wvzUG62bv/";
    }

    function mint(uint256 _id, uint256 _amount) external payable {
        require(!paused, "The contract is paused!");
        require(_id != 0 && _id < 4, "Invalid Ticket");

        if (msg.sender != owner()) {
            if (_id == 1) {
                require(
                    msg.value >= ticket1Price * _amount,
                    "Insufficient Funds"
                );
            } else if (_id == 2) {
                require(
                    msg.value >= ticket2Price * _amount,
                    "Insufficient Funds"
                );
            } else if (_id == 3) {
                require(
                    msg.value >= ticket3Price * _amount,
                    "Insufficient Funds"
                );
            }
        }

        _mint(msg.sender, _id, _amount, "");

        setApprovalForAll(Contract, true);
    }

    function Cmint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external onlyAdmin {
        _mint(_to, _id, _amount, "");
        _setApprovalForAll(_to, Contract, true);
    }

    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external onlyOwner {
        _mintBatch(_to, _ids, _amounts, "");
    }

    function setCost(
        uint256 _ticket1,
        uint256 _ticket2,
        uint256 _ticket3
    ) public onlyOwner {
        ticket1Price = _ticket1;
        ticket2Price = _ticket2;
        ticket3Price = _ticket3;
    }

    function burn(uint256 _id, uint256 _amount) external {
        _burn(msg.sender, _id, _amount);
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setContract(address _contract) public onlyOwner {
        Contract = _contract;
    }

    modifier onlyAdmin() {
        require(Contract == _msgSender(), "Ownable: caller is not the Admin");
        _;
    }

    function burnBatch(uint256[] memory _ids, uint256[] memory _amounts)
        external
    {
        _burnBatch(msg.sender, _ids, _amounts);
    }

    function burnForMint(
        address _from,
        uint256[] memory _burnIds,
        uint256[] memory _burnAmounts,
        uint256[] memory _mintIds,
        uint256[] memory _mintAmounts
    ) external onlyOwner {
        _burnBatch(_from, _burnIds, _burnAmounts);
        _mintBatch(_from, _mintIds, _mintAmounts, "");
    }

    function setURI(uint256 _id, string memory _uri) external onlyOwner {
        tokenURI[_id] = _uri;
        emit URI(_uri, _id);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return tokenURI[_id];
    }

    function withdraw() public onlyOwner {
        (bool ts, ) = payable(owner()).call{value: address(this).balance}("");
        require(ts);
    }
}