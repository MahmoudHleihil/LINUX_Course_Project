import java.awt.*;
import java.awt.image.*;
import java.io.*;
import javax.imageio.ImageIO;

public class WatermarkAdder {
    public static void main(String[] args) {
        if (args.length < 2) {
            System.out.println("Usage: java WatermarkAdder <folder> <watermark_text>");
            return;
        }

        File folder = new File(args[0]);
        String watermarkText = args[1];

        if (!folder.exists() || !folder.isDirectory()) {
            System.out.println("Error: Folder not found.");
            return;
        }

        File[] files = folder.listFiles((dir, name) -> name.toLowerCase().endsWith(".png"));
        if (files == null || files.length == 0) {
            System.out.println("No PNG images found.");
            return;
        }

        for (File file : files) {
            try {
                BufferedImage image = ImageIO.read(file);
                Graphics2D g2d = image.createGraphics();
                g2d.setFont(new Font("Arial", Font.BOLD, 36));
                g2d.setColor(new Color(255, 0, 0, 128));
                g2d.drawString(watermarkText, 20, image.getHeight() - 20);
                g2d.dispose();

                File output = new File(folder, "watermarked_" + file.getName());
                ImageIO.write(image, "png", output);
                System.out.println("Watermark added to: " + output.getName());
            } catch (IOException e) {
                System.out.println("Error processing file: " + file.getName());
            }
        }
    }
}
