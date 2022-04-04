//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Unsafe.sol";

contract StoreAndRetrieve is Unsafe {
    enum ResourceType {
        image,
        text,
        video,
        hyperlink
    }
    struct Resource {
        uint256 id;
        ResourceType rType;
        string resource_hash;
        bool isPrivate;
    }

    mapping(uint256 => address) p2u;
    mapping(address => uint256[]) u2p;
    mapping(uint256 => Resource[]) p2r;
    mapping(uint256 => string) p2motto;
    mapping(uint256 => string) p2lifetime;
    mapping(uint256 => string) p2name;
    mapping(uint256 => string) p2headline;

    mapping(address => uint256[]) u2gid;
    mapping(uint256 => uint256[]) gid2p;
    mapping(uint256 => uint256) p2gid;
    mapping(address => mapping(uint256 => bool)) u2pToAssign;
    mapping(uint256 => string) gid2name;

    mapping(uint256 => mapping(address => bool)) auth;
    uint256 public perpetuityId = 0;
    uint256 public groupId = 0;
    uint256 public resourceCount = 0;

    function purchasePerpetuity() public payable {
        require(msg.value >= 0.01 ether, "insufficient fee");
        require(perpetuityId <= 2**256 - 1, "all sold out");
        p2u[perpetuityId] = msg.sender;
        u2p[msg.sender].push(perpetuityId);
        perpetuityId++;
    }

    function setMotto(uint256 perpetuity, string memory motto) public {
        require(p2u[perpetuity] == msg.sender, "owner ONLY");
        p2motto[perpetuity] = motto;
    }

    function setLifetime(uint256 perpetuity, string memory lifetime) public {
        require(p2u[perpetuity] == msg.sender, "owner ONLY");
        p2lifetime[perpetuity] = lifetime;
    }

    function setName(uint256 perpetuity, string memory name) public {
        require(p2u[perpetuity] == msg.sender, "owner ONLY");
        p2name[perpetuity] = name;
    }

    function setHeadline(uint256 perpetuity, string memory headline) public {
        require(p2u[perpetuity] == msg.sender, "owner ONLY");
        p2headline[perpetuity] = headline;
    }

    function batchPurchaseWithDirectAssignment(
        uint256 num,
        string memory name,
        address[] memory addrs
    ) public payable {
        require(msg.value >= num * 10**16 + 10**17, "insufficient fee");
        require(perpetuityId + num <= 2**256 - 1, "sold out");
        gid2name[groupId] = name;
        for (uint256 i = 0; i < num; i++) {
            gid2p[groupId].push(perpetuityId);
            p2gid[perpetuityId] = groupId;
            if (i < addrs.length) {
                u2gid[addrs[i]].push(groupId);
                u2p[addrs[i]].push(perpetuityId);
            } else {
                u2pToAssign[msg.sender][perpetuityId] = true;
            }
            perpetuityId++;
        }
        groupId++;
    }

    function batchPurchase(uint256 num, string memory name) public payable {
        require(msg.value >= num * 10**16 + 10**17, "insufficient fee");
        require(perpetuityId + num <= 2**256 - 1, "sold out");
        gid2name[groupId] = name;
        for (uint256 i = 0; i < num; i++) {
            gid2p[groupId].push(perpetuityId);
            u2pToAssign[msg.sender][perpetuityId] = true;
            perpetuityId++;
        }
        groupId++;
    }

    function assignPerpetuityToGroupMember(address to, uint256 _perpetuityId)
        public
    {
        require(
            u2pToAssign[msg.sender][_perpetuityId] == true,
            "not the owner of this perpetuity"
        );
        u2pToAssign[msg.sender][_perpetuityId] == false;
        u2p[to].push(_perpetuityId);
        u2gid[to].push(p2gid[_perpetuityId]);
    }

    function changeGroupName(uint256 gid, string memory name) public {
        for (uint256 i = 0; i < u2gid[msg.sender].length; i++) {
            if (u2gid[msg.sender][i] == gid) {
                gid2name[gid] = name;
                return;
            }
        }
    }

    function perpetuityOf(address owner)
        public
        view
        returns (uint256[] memory)
    {
        return u2p[owner];
    }

    function perpetuityOf(uint256 group)
        public
        view
        returns (uint256[] memory)
    {
        return gid2p[group];
    }

    function groupOf(address member) public view returns (uint256[] memory) {
        return u2gid[member];
    }

    function groupOf(uint256 perpetuity) public view returns (uint256) {
        return p2gid[perpetuity];
    }

    function viewResourceByPerpetuity(uint256 perpetuity)
        public
        view
        returns (Resource[] memory)
    {
        Resource[] memory ret = p2r[perpetuity];
        for (uint256 i = 0; i < ret.length; i++) {
            uint256 id = ret[i].id;
            if (ret[i].isPrivate && auth[id][msg.sender] != true)
                ret[i].resource_hash = "";
        }
        return ret;
    }

    function storeResouce(
        string calldata _hash,
        uint256 perpetuity,
        ResourceType t
    ) public {
        _storeResource(_hash, perpetuity, t, false);
    }

    function storeResourceWithAuthManagement(
        string calldata _hash,
        uint256 perpetuity,
        ResourceType t,
        address[] calldata addrs
    ) public {
        _storeResource(_hash, perpetuity, t, true);
        for (uint256 i = 0; i < addrs.length; i++) {
            auth[resourceCount][addrs[i]] = true;
        }
        auth[resourceCount][msg.sender] = true;
    }

    function _storeResource(
        string calldata _hash,
        uint256 perpetuity,
        ResourceType t,
        bool isPrivate
    ) private {
        require(
            p2u[perpetuity] == msg.sender,
            "msg sender is NOT the owner of this Perpetuity"
        );
        Resource[] storage rs = p2r[perpetuity];
        Resource memory r = Resource(resourceCount, t, _hash, isPrivate);
        rs.push(r);
    }

    function getBalance() public view adminView returns (uint256) {
        return address(this).balance;
    }

    function nameOf(uint256 group) public view returns (string memory) {
        return gid2name[group];
    }
}