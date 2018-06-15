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
    function _createHut(
        uint256 _standNumber,
        address _owner
    )
        public
        returns (uint);
   

        Hut memory _hut = hut({
            constructionTime: uint64(now),
            standNumber: uint256(_standNumber),
        });
        uint256 newhutId = huts.push(_hut) - 1;

        // emit the birth event
        Birth(
            _owner,
            newhutId,
            uint256(_hut.standNumber),
        );

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(0, _owner, newhutId);

        return newhutId;
    }

}
