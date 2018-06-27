pragma solidity ^0.4.24;

import "./ERC721Basic.sol";


/// @title CreatingaHut.sol. Holds all common structs, events and base variables
/// for the construction of huts on the blockchain.

contract CreatingaHut {

    /*** EVENTS ***/

    ///  The Construction event is fired whenever a new hut comes into existence on the blockchain.
    event Construction(address owner, uint256 hutId, uint256 standNumber);

    ///  Transfer event as defined in current draft of ERC721. Emitted every time a hut
    ///  ownership is assigned.
    event Transfer(address from, address to, uint256 hutId);

    /*** DATA TYPES ***/

    ///  The main hut struct. Every hut created in the dApp is represented by a copy
    ///  of this structure.
    struct Hut {
        // The Hut's stand number is packed into these 256-bits, the format is 
        // as represented on the original paper form deed! A hut's stand number never changes.
        uint256 standNumber;

        // The timestamp from the block when this hut came into existence on the blockchain.
        uint64 constructionTime;
        
        // NOTE: This is the circumference of the full space allocated to the hut 
        // according to the paper deed and not the measurement of any property held inside 
        // the hut.
        string circumference;
        // The country from which the standNumber originates from.
        string coutry;
        // The number of bedrooms fitted in the property that is built inside the hut.
        string bedrooms;
        // The number of bathrooms fitted in the property that is built inside the hut.
        string bathrooms;
    }

   

    /*** STORAGE ***/

    ///  An array containing the Hut struct for all huts in existence. The ID
    ///  of each hut is actually an index into this array. 
    Hut [] huts;

    ///  A mapping from hut IDs to the address that owns them. All huts have
    ///  some valid owner address.
    mapping (uint256 => address) public hutIndexToOwner;

    //  A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) ownershipTokenCount;

    ///  A mapping from HutIDs to an address that has been approved to call
    ///  transferFrom(). Each hut can only have one approved address for transfer
    ///  at any time. A zero value means no approval is outstanding.
    mapping (uint256 => address) public hutIndexToApproved;

    /// The contract owner can change the base URL, in case it becomes necessary. It is needed for Metadata.
    /// and will define information about properties kept inside huts.
   string public url = "http://example.com/";

    ///  Assigns ownership of a specific Hut to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        // Since the number of huts is capped at 2^32 due to uint256
        // there is no overflow to this, at least in this century
        ownershipTokenCount[_to]++;
        // transfer ownership
        hutIndexToOwner[_tokenId] = _to;
        //When creating a new hut _from is 0x0, but we cant account this address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            // Once the hut ownership is transfered, clear any previously approved 
            // ownership exchange.
            delete hutIndexToApproved [_tokenId];
        }
       
        
        // Emit the transfer event.
        Transfer(_from, _to, _tokenId);
    }

    ///  An public method that creates a new hut and stores it. This
    ///  method doesn't do any checking and should only be called when the
    ///  input data is known to be valid. Will generate both a Construction event
    ///  and a Transfer event. Function only public for demo reasons.
    /// @param _standNumber Also derived from the original title deed.
    /// @param _owner The inital owner of this hut, must be non-zero.
    /// @param _circumference The whole measurement of the hut, not neccessarily the property inside.
    /// @param _country The jurisdiction in which the hut was issued.
    /// @param _bedrooms The number of bedrooms inside the said hut.
    /// @param _bathrooms The number of bathrooms inside the said hut.
    function _createHut(
        uint256 _standNumber,
        address _owner,
        string  _circumference,
        string _country,
        string _bedrooms,
        string _bathrooms,
    )
        public
        returns (uint)
        
    {}

        Hut memory _hut = hut({
            constructionTime: uint64(now),
            standNumber: uint256(_standNumber),
            circumference: string(_circumference),
            country: string(_country),
            bedrooms: string(_bedrooms),
            bathrooms: string(_bathrooms)
        });
        uint256 newhutId = huts.push(_hut) - 1;

        // emit the Construction event
        Construction(
            _owner,
            newhutId,
            uint256(_hut.standNumber),
            _hut.circumference,
            _hut.country,
            _hut.bedrooms,
            _hut.bathroomms
        );

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(0, _owner, newhutId);

        return newhutId;
    }

}
