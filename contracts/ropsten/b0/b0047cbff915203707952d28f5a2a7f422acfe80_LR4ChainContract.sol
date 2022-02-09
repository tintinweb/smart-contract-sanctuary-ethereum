// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import './LR4Ownable.sol';
import './LR4Sealed.sol';
import './LR4Common.sol';
import './LR4Killable.sol';



contract LR4ChainContract is LR4Ownable,  LR4Sealed, LR4Common, LR4Killable {
    string year;
    string company;

    constructor ( string memory _year, string memory _company) {
        year = _year;
        company = _company;
    }

     //mapping  key = parcel code, value = parcel
    mapping (uint256 => Parcel) public parcelList;
    //mapping key = parcel code , value  = array of crop operations
    mapping (uint256 => uint256  []) public parcelCropOperations;
    //mapping key = parcel code, value = array of harvest codes
    mapping (uint256 => uint256  []) private parcelHarvestString;
    //mapping key = concat of parcel code and harvest code, value = harvest
    mapping (string => Harvest)  private harvestList;
    //mapping key = concat of parcel code and harvest code, value = array of crop operations
    mapping (string => CropOperation []) public harvestCropOperations;
    //mapping key = concat of parcel code and crop operation code, value = crop operation
    mapping (string => CropOperation ) private cropOperations;
    //mapping key = concat of parcel code and crop operation code, value = analysis
    mapping (string => Analysis ) private cropAnalysis;
    //mapping key = concat of parcel code and harvest code, value = analysis
    mapping (string => Analysis ) private harvestAnalysis;

   //add new parcel
    function addParcel(uint256 _code, string memory _name, string memory  _urlPdf, string memory _urlTranslatedPdf, 
      string  memory _hashPdf, string memory _cropType, string memory _translatedCropType,
      uint256  _timestamp ) onlyOwner onlyIfNotSealed external{
            require(parcelList[_code].exists ==0, strExtParcel);
            parcelList[_code] = Parcel({urlPdf: _urlPdf, hashPdf:_hashPdf, datePdf: _timestamp, code: _code,
             name: _name, cropType: _cropType, exists: 1, isOpen: 1, closure_date: 0,  translatedCropType: _translatedCropType,
             urlTranslatedPdf: _urlTranslatedPdf});
    }
    //add new crop operation to existing parcel
    function addCropOperation(uint256 _parcelCode, uint256 _cropCode, string memory _urlTranslatedPdf, 
        string memory _urlPdf, string  memory _hashPdf, uint256 _timestamp) onlyOwner onlyIfNotSealed external {
            //check if parcel exists, if not throws exception
            require(parcelList[_parcelCode].exists==1, strNotExtParcel);
            //check if parcel is not closed otherwise throws exception
            require(parcelList[_parcelCode].isOpen==1, strValidParcel);
            //create key for cropOperations
            string memory keyCrop = concat(toString(_parcelCode),"|", toString(_cropCode));
            //check if code of crop operation not exists, otherwise throw exception
            require(cropOperations[keyCrop].exists==0, strExtCrop);
            // add crop code to the list of all crop operations code for parcel code
            parcelCropOperations[_parcelCode].push(_cropCode);
            cropOperations[keyCrop].urlPdf  = _urlPdf;
            cropOperations[keyCrop].hashPdf  = _hashPdf;
            cropOperations[keyCrop].datePdf  = _timestamp;
            cropOperations[keyCrop].code = _cropCode;
            cropOperations[keyCrop].urlTranslatedPdf = _urlTranslatedPdf;
            cropOperations[keyCrop].exists = 1;
            cropOperations[keyCrop].urlPdfAnalysis= '';
            cropOperations[keyCrop].hashPdfAnalysis='';
            cropOperations[keyCrop].urlTranslatedPdfAnalysis= '';
            cropOperations[keyCrop].datePdfAnalysis=0;
            cropOperations[keyCrop].analysisResult='';
            cropOperations[keyCrop].labName='';
    }

    //close parcel
    function closeParcel(uint256 _parcelCode, uint256 _timestamp)  onlyOwner onlyIfNotSealed external{
        require(parcelList[_parcelCode].exists ==1, strNotExtParcel);
        parcelList[_parcelCode].isOpen = 0;
        parcelList[_parcelCode].closure_date = _timestamp;
    }

    //add harvest associated to parcel
     function addHarvest(uint256 _parcelCode, uint256 _harvestCode, string memory _harvestName, string memory _recipientCompany,
        string memory _urlPdf, string  memory _hashPdf,  string memory _urlTranslatedPdf,
         uint256 _timestamp, uint256 _dateHarvest) onlyOwner onlyIfNotSealed external {
            // check if parcel exists
            require(parcelList[_parcelCode].exists==1, strNotExtParcel);
            //check if parcel is not closed yet
            require(parcelList[_parcelCode].isOpen==1, strValidParcel);
            
            
            //create key per parcel and harvest
            string memory keyParcelHarvest = concat(toString(_parcelCode),"|", toString(_harvestCode));
            //check if harvest exists
            require(harvestList[keyParcelHarvest].exists==0, strExtHarvest);
            //get all code of crop operation for parcel
            require(parcelCropOperations[_parcelCode].length > 0,  strHarvestCrops);
            //add code of harvest to the list of all harvest for parcel code
            parcelHarvestString[_parcelCode].push(_harvestCode);
            harvestList[keyParcelHarvest].urlPdf = _urlPdf;
            harvestList[keyParcelHarvest].hashPdf = _hashPdf;
            harvestList[keyParcelHarvest].urlTranslatedPdf = _urlTranslatedPdf;
            harvestList[keyParcelHarvest].datePdf = _timestamp;
            harvestList[keyParcelHarvest].dateHarvest = _dateHarvest;
            harvestList[keyParcelHarvest].code = _harvestCode;
            harvestList[keyParcelHarvest].name = _harvestName;
            harvestList[keyParcelHarvest].recipientCompany = _recipientCompany;
            harvestList[keyParcelHarvest].exists = 1;
            uint256 [] memory codes = parcelCropOperations[_parcelCode];
            for (uint _iCrops = 0; _iCrops < codes.length; _iCrops ++ ) {
                CropOperation memory op = cropOperations[concat(toString(_parcelCode),"|", toString( codes[_iCrops]))];
                harvestCropOperations[keyParcelHarvest].push(op);
            }
              
    }

    //add analysis of crop operation
    function addCropAnalysis(uint256 _parcelCode,  uint256 _cropCode,  
         string memory _urlPdf, string  memory _hashPdf, string memory _urlTranslatedPdf, 
         uint256 _timestamp, string memory _analysisResult, string memory _labName ) onlyOwner onlyIfNotSealed external {
            //check if parcel exists
             require(parcelList[_parcelCode].exists==1, strNotExtParcel);
             //check if parcel is open
             require(parcelList[_parcelCode].isOpen==1, strValidParcel);
             string memory keyParcelCrop = concat(toString(_parcelCode),"|", toString(_cropCode));
             //check if crop operation associated  exists
             require(cropOperations[keyParcelCrop].exists ==1, strNotExtCrop);
             cropOperations[keyParcelCrop].urlPdfAnalysis = _urlPdf;
             cropOperations[keyParcelCrop].hashPdfAnalysis = _hashPdf;
             cropOperations[keyParcelCrop].urlTranslatedPdfAnalysis = _urlTranslatedPdf;
             cropOperations[keyParcelCrop].datePdfAnalysis= _timestamp;
             cropOperations[keyParcelCrop].analysisResult= _analysisResult;
             cropOperations[keyParcelCrop].labName= _labName;
        }

    //add analysis of harvest
    function addHarvestAnalysis(uint256 _parcelCode, uint256  _harvestCode, 
        uint256 _analysisCode,  string memory _urlPdf, 
        string memory _urlTranslatedPdf,
        string  memory _hashPdf, uint256 _timestamp, string memory _analysisResult, string memory _labName) onlyOwner onlyIfNotSealed external {
            //check if parcel exists
            require(parcelList[_parcelCode].exists ==1, strNotExtParcel);
            //check if parcel is open
            require(parcelList[_parcelCode].isOpen ==1, strValidParcel);
            string memory compositeKey = concat(toString(_parcelCode), "|", toString(_harvestCode));
            //check if harvest associated to analysis exists
            require(harvestList[compositeKey].exists==1, strNotExtHarvest);
           harvestAnalysis[compositeKey] = Analysis({urlPdf:_urlPdf,hashPdf: _hashPdf,datePdf: _timestamp, code:_analysisCode, 
           urlTranslatedPdf: _urlTranslatedPdf, analysisResult: _analysisResult, labName: _labName});
        }
    

    //get harvest with information about parcel and crop operations
    function getHarvest(uint256 _parcelCode, uint256 _harvestCode) external view  returns (string memory, string memory,  Parcel memory, CropOperation [] memory, Harvest memory, Analysis memory) {
        string memory compositeKey = concat(toString(_parcelCode),"|", toString(_harvestCode));
        return (year, company, parcelList[_parcelCode], harvestCropOperations[compositeKey] ,harvestList[compositeKey], harvestAnalysis[compositeKey]);
    }

}