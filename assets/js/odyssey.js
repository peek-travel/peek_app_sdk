import live_select from "live_select"

// Function to add global event listeners
function addOdysseyGlobalEvents(windowObj) {
  // Global event listener for triggering input events on form fields, this is
  // needed for input fields that maintain a hidden input field behind the scenes
  // and need to tell the parent form when a change has been made.
  windowObj.addEventListener("phx:trigger-input", (event) => {
    const { field_id } = event.detail
    const input = windowObj.document.getElementById(field_id)
    if (input) {
      input.dispatchEvent(new Event('input', { bubbles: true }))
    }
  })
}

const OdysseyHooks = {
    ...live_select,
    OdysseyActivityPicker: {
    mounted () {
      const picker = this.el.querySelector('odyssey-product-picker')

      if (picker) {
        picker.addEventListener('click', event => {
          event.preventDefault()
          event.stopPropagation()
        })

        picker.addEventListener('change', event => {
          event.preventDefault()
          event.stopPropagation()

          const hiddenInput = this.el.querySelector('input[type="hidden"]')
          hiddenInput.value = event.detail.selectedIds.join(',')

          // Trigger a change event on the hidden input to notify Phoenix
          hiddenInput.dispatchEvent(new Event('input', { bubbles: true }))
        })
      }
    }
  }
}

export { OdysseyHooks, addOdysseyGlobalEvents }
export default OdysseyHooks
