import places from 'places.js';

const initAutocomplete = () => {
  const addressInput = document.getElementById('itinerary_address');
  if (addressInput) {
    places({ container: addressInput });
  }
};

export default initAutocomplete;
