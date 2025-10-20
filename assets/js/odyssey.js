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
  },
  ToastHook: {
    mounted () {
      setTimeout(() => {
        this.hideToast()
      }, 3000)

      const closeButton = this.el.querySelector('[data-close-toast]')
      if (closeButton) {
        closeButton.addEventListener('click', e => {
          e.preventDefault()
          this.hideToast()
        })
      }
    },

    hideToast () {
      const element = this.el
      if (element) {
        element.style.opacity = '0'
        element.style.transform = 'translateX(100%)'
        element.style.transition = 'all 0.3s ease-in-out'

        setTimeout(() => {
          element.remove()
        }, 300)
      }
    }
  }
}

export default Hooks
