/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Dploma {

    struct Certification {
        address dip_addr_certifier;
        address dip_addr_certified;
        Certified dip_certified;
        Certifier dip_cedrtifier;
        Template dip_template;
    }

    struct Template {
        string temp_title;
        string temp_name;
        string temp_date;
        string[] temp_spec;
    }

    struct Certified {
        string cfied_firstname;
        string cfied_lastname;
        string cfied_birthdate;
    }

    struct Certifier {
        string cfier_name;
        string cfier_adress;
    }

    mapping(bytes32 => Certification) private map_cert;
    mapping(bytes32 => Template) private map_temp;
    mapping(bytes32 => Certified) private unvisibleCertified;
    mapping(bytes32 => bool) private studentVisibility;
    uint256 private templateId = 0;

    event evtTemplate(string, bytes32);
    event certifCreation(string, bytes32);
    event modificationMsg(string);
    event evtVisisbility(string);
    event deletedCertif(string);


    function createhashOwner(address _addrS) private view returns (bytes32) {
        return keccak256(abi.encode(msg.sender, _addrS, block.timestamp));
    }


    function createTemplate(
        string memory _title,
        string memory _name,
        string memory _date,
        string[] memory _specs
    ) public returns (bytes32) {
        templateId += 1;
        bytes32 hashTemplate = keccak256(abi.encode(templateId));
        map_temp[hashTemplate] = Template(_title, _name, _date, _specs);

        emit evtTemplate("Template access key", hashTemplate);
        return hashTemplate;
    }

    function getTemplate(bytes32 _hashTemplate)
        private
        view
        returns (Template memory)
    {
        return map_temp[_hashTemplate];
    }


    function insertWithTemplate(
        string memory _cfied_firstname,
        string memory _cfied_lastname,
        string memory _cfied_birthdate,
        string memory _cfier_name,
        string memory _cfier_adress,
        bytes32 _hashTemplate,
        address _certified_pub_adress
    ) public returns (bytes32) {
        bytes32 idCert = createhashOwner(_certified_pub_adress);
        Template memory temp = getTemplate(_hashTemplate);
        map_cert[idCert] = Certification(
            msg.sender,
            _certified_pub_adress,
            Certified(_cfied_firstname, _cfied_lastname, _cfied_birthdate),
            Certifier(_cfier_name, _cfier_adress),
            temp
        );
        studentVisibility[idCert] = true;
        emit certifCreation("Certification access key", idCert);
        return idCert;
    }

    function insertWithoutTemplate(
        string memory _cfied_firstname,
        string memory _cfied_lastname,
        string memory _cfied_birthdate,
        string memory _cfier_name,
        string memory _cfier_adress,
        address _certified_pub_adress,
        string memory _title,
        string memory _name,
        string memory _date,
        string[] memory _specs
    ) public returns (bytes32) {
        bytes32 idCert = createhashOwner(_certified_pub_adress);

        //data insertion
        map_cert[idCert] = Certification(
            msg.sender,
            _certified_pub_adress,
            Certified(_cfied_firstname, _cfied_lastname, _cfied_birthdate),
            Certifier(_cfier_name, _cfier_adress),
            Template(_title, _name, _date, _specs)
        );
        studentVisibility[idCert] = true;
        emit certifCreation("Certification access key", idCert);
        return idCert;
    }

    Certified unknowCertifed = Certified("hidden", "hidden", "hidden");

    function toggleStudentVisibility(bytes32 _hashCert) public {
        require(map_cert[_hashCert].dip_addr_certified == msg.sender);
        studentVisibility[_hashCert] = !studentVisibility[_hashCert];
        emit evtVisisbility("Certified public visbility has changed");
    }

    function getCertification(bytes32 _hashCert)
        public
        view
        returns (Certification memory)
    {
        Certification memory cert = map_cert[_hashCert];
        if (!studentVisibility[_hashCert]) {
            cert.dip_certified = unknowCertifed;
        }
        return cert;
    }

    function setTemplateTitle(bytes32 _hashCert, string memory _title) private {
        Certification storage cert = map_cert[_hashCert];
        cert.dip_template.temp_title = _title;
    }

    function setTemplateName(bytes32 _hashCert, string memory _name) private {
        Certification storage cert = map_cert[_hashCert];
        cert.dip_template.temp_name = _name;
    }

    function setTemplateDate(bytes32 _hashCert, string memory _date) private {
        Certification storage cert = map_cert[_hashCert];
        cert.dip_template.temp_date = _date;
    }

    function setTemplateSpecs(bytes32 _hashCert, string[] memory _specs)
        private
    {
        Certification storage cert = map_cert[_hashCert];
        cert.dip_template.temp_spec = _specs;
    }

    function ModifyTemplate(
        bytes32 _hashCert,
        string memory _title,
        string memory _name,
        string memory _date,
        string[] memory _specs
    ) public {
       require(map_cert[_hashCert].dip_addr_certifier == msg.sender);
        setTemplateTitle(_hashCert, _title);
        setTemplateName(_hashCert, _name);
        setTemplateDate(_hashCert, _date);
        setTemplateSpecs(_hashCert, _specs);

        emit modificationMsg("Certification data has been modified");
    }

    function DeleteCertif(bytes32 _hashCert) public {
        require(map_cert[_hashCert].dip_addr_certifier == msg.sender);
        delete map_cert[_hashCert];
    }
}