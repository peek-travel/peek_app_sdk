const Hooks = {
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

export default Hooks
