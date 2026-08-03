const copyButtons = document.querySelectorAll('[data-copy]');

copyButtons.forEach((button) => {
  button.addEventListener('click', async () => {
    const originalText = button.textContent;
    try {
      await navigator.clipboard.writeText(button.dataset.copy);
      button.textContent = 'COPIADO';
    } catch (error) {
      button.textContent = 'SELECIONE';
      console.warn('Não foi possível copiar automaticamente.', error);
    }

    window.setTimeout(() => {
      button.textContent = originalText;
    }, 1600);
  });
});
