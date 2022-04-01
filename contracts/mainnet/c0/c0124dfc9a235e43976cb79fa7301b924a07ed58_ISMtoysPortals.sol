/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ISMtoysPortals {
    struct Collection {
        address contract_address;
        uint256 price;
        bool whitelisted;
        bool only_holder;
        Revenue[] revenue;
    }

    struct Revenue {
        address account;
        uint256 percentage;
    }

    struct Portal {
        mapping(address => Collection) collections;
        bool active;
        bool defined;
    }

    struct Resume {
        address contract_address;
        uint256[] itemsIds;
        uint256 quantity;
    }

    mapping(address => uint256) total_balances;
    mapping(uint256 => Portal) portals;
    uint256 public portalsRegistered;
    address public owner;

    event TransactionEvent(
        address from,
        address to,
        uint256 value,
        uint256 portalId
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "You're not the owner of the contract");
        _;
    }

    constructor(Collection[][] memory _portals, uint256[] memory portalsIds) {
        portalsRegistered = 0;
        owner = msg.sender;
        registerMultiplePortals(_portals, portalsIds);
    }

    function registerMultiplePortals(
        Collection[][] memory _portals,
        uint256[] memory portalsIds
    ) public onlyOwner returns (bool) {
        for (uint256 i = 0; i < _portals.length; i++) {
            registerPortal(_portals[i], portalsIds[i]);
        }
        return true;
    }

    function registerPortal(Collection[] memory _portal, uint256 portalId)
        public
        onlyOwner
        returns (bool)
    {
        require(!portals[portalId].defined, "portalId in use");

        for (uint256 i = 0; i < _portal.length; i++) {
            addRevenueOrFail(
                portalId,
                _portal[i].revenue,
                _portal[i].contract_address
            );
            portals[portalId]
                .collections[_portal[i].contract_address]
                .price = _portal[i].price;
            portals[portalId]
                .collections[_portal[i].contract_address]
                .only_holder = _portal[i].only_holder;
            portals[portalId]
                .collections[_portal[i].contract_address]
                .whitelisted = true;
        }

        portals[portalId].active = true;
        portals[portalId].defined = true;
        portalsRegistered++;
        return true;
    }

    function removePortal(uint256 portalId) public onlyOwner returns (bool) {
        portals[portalId].active = false;
        return true;
    }

    function activePortal(uint256 portalId) public onlyOwner returns (bool) {
        portals[portalId].active = true;
        return true;
    }

    function addRevenueOrFail(
        uint256 portalId,
        Revenue[] memory _revenue,
        address contract_address
    ) private {
        uint256 total = 0;
        Revenue memory rev;
        for (uint256 i = 0; i < _revenue.length; i++) {
            total += _revenue[i].percentage;
            rev.account = _revenue[i].account;
            rev.percentage = _revenue[i].percentage;
            portals[portalId].collections[contract_address].revenue.push(rev);
        }
        require(total == 100, "Revenue percentages must sum 100");
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function deposit(uint256 portalId, Resume[] memory _resume)
        external
        payable
        returns (bool)
    {
        validateTokensAndValue(portalId, _resume);
        emit TransactionEvent(msg.sender, address(0), msg.value, portalId);
        return true;
    }

    function validateTokensAndValue(uint256 portalId, Resume[] memory _resume)
        private
    {
        require(portals[portalId].active, "Portal inactive");
        Resume memory currentResume;
        uint256 price;
        uint256 resumeLength = _resume.length;
        require(resumeLength > 0, "No data provided");

        for (uint256 i = 0; i < resumeLength; i++) {
            currentResume.contract_address = _resume[i].contract_address;
            currentResume.itemsIds = _resume[i].itemsIds;
            currentResume.quantity = _resume[i].quantity;
            require(
                portals[portalId]
                    .collections[currentResume.contract_address]
                    .whitelisted,
                "Invalid collection"
            );
            uint256 current_items_quantity = currentResume.itemsIds.length;
            require(current_items_quantity > 0, "No tokens provided");
            if (
                portals[portalId]
                    .collections[currentResume.contract_address]
                    .only_holder
            ) {
                for (uint256 j = 0; j < currentResume.itemsIds.length; j++) {
                    // call to collection contract
                    require(
                        msg.sender ==
                            CollectionContract(currentResume.contract_address)
                                .ownerOf(currentResume.itemsIds[j]),
                        "Invalid tokensId"
                    );
                }
            }
            price +=
                portals[portalId]
                    .collections[currentResume.contract_address]
                    .price *
                currentResume.quantity;
            shareRevenue(portalId, currentResume);
        }
        require(price != 0, "Invalid quantity");
        require(msg.value == price, "Invalid amount");
    }

    function shareRevenue(uint256 portalId, Resume memory _resume) private {
        Collection memory collection = portals[portalId].collections[
            _resume.contract_address
        ];
        Revenue[] memory revs = collection.revenue;
        uint256 value = collection.price * _resume.quantity;
        uint256 total_distributed = 0;
        uint256 curr_val;
        for (uint256 i = 0; i < revs.length - 1; i++) {
            curr_val = (value * revs[i].percentage) / 100;
            total_balances[revs[i].account] += curr_val;
            total_distributed += curr_val;
        }
        total_balances[revs[revs.length - 1].account] +=
            value -
            total_distributed;
    }

    function getBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function getAccountBalance() external view returns (uint256) {
        return total_balances[msg.sender];
    }

    function getPrice(uint256 portalId, address contract_address)
        external
        view
        returns (uint256)
    {
        return portals[portalId].collections[contract_address].price;
    }

    function withdraw(uint256 amount) external returns (bool) {
        require(amount <= total_balances[msg.sender], "Insufficient funds");
        // send amount ether in this contract to owner
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
        total_balances[msg.sender] -= amount;
        emit TransactionEvent(address(0), msg.sender, amount, 0);
        return true;
    }
}

// ABI definition of collections
contract CollectionContract {
    function ownerOf(uint256 tokenId) public returns (address) {}
}